from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import boto3
from botocore.exceptions import ClientError
from botocore.config import Config as BotoConfig
from datetime import datetime
import uuid
import os
from pydantic import BaseModel
from app.db.session import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.record import MedicalRecord
from app.models.attachment import Attachment
from app.schemas.record import AttachmentBase
from app.core.security import get_current_user
from app.core.config import settings

router = APIRouter()


# Configurar cliente S3/MinIO
def get_s3_client():
    """Retorna cliente S3 configurado"""
    return boto3.client(
        's3',
        endpoint_url=settings.S3_ENDPOINT,
        aws_access_key_id=settings.S3_ACCESS_KEY,
        aws_secret_access_key=settings.S3_SECRET_KEY,
        region_name=settings.S3_REGION,
        config=BotoConfig(signature_version='s3v4'),
    )


def ensure_bucket_exists(s3_client):
    """Garante que o bucket existe"""
    try:
        s3_client.head_bucket(Bucket=settings.S3_BUCKET)
    except ClientError:
        s3_client.create_bucket(Bucket=settings.S3_BUCKET)


def get_s3_key_from_url(file_url: str) -> str:
    """Extrai a chave S3 da URL"""
    if f"{settings.S3_BUCKET}/" in file_url:
        return file_url.split(f"{settings.S3_BUCKET}/")[-1]
    return file_url


def check_record_access(record_id: int, user: User, db: Session) -> MedicalRecord:
    """Verifica se o usuário tem acesso ao registro médico"""
    record = db.query(MedicalRecord).filter(MedicalRecord.id == record_id).first()
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro não encontrado",
        )
    
    pet = db.query(Pet).filter(Pet.id == record.pet_id).first()
    if not pet or pet.owner_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar este registro",
        )
    
    return record


# Schemas para presigned URL
class PresignedUrlResponse(BaseModel):
    url: str
    expires_in: int
    file_name: str


class AttachmentWithPresignedUrl(AttachmentBase):
    download_url: Optional[str] = None


@router.post("/{record_id}/attachments", response_model=AttachmentBase, status_code=status.HTTP_201_CREATED)
async def upload_attachment(
    record_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Upload de anexo para um registro médico.
    
    Aceita PDF, imagens e documentos.
    Tamanho máximo recomendado: 10MB.
    """
    # Verifica acesso ao registro
    check_record_access(record_id, current_user, db)
    
    s3_client = get_s3_client()
    ensure_bucket_exists(s3_client)
    
    # Gera nome único do arquivo
    file_extension = os.path.splitext(file.filename)[1] if file.filename else ""
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    s3_key = f"records/{record_id}/{unique_filename}"
    
    # Faz upload para S3/MinIO
    try:
        file_contents = await file.read()
        file_size = len(file_contents)
        
        s3_client.put_object(
            Bucket=settings.S3_BUCKET,
            Key=s3_key,
            Body=file_contents,
            ContentType=file.content_type or "application/octet-stream",
        )
        
        # Armazena o s3_key como file_url (mais seguro)
        # URL completa será gerada via presigned URL
        file_url = s3_key
        
        # Salva no banco
        attachment = Attachment(
            record_id=record_id,
            file_url=file_url,
            file_name=file.filename or unique_filename,
            mime_type=file.content_type,
            file_size=file_size,
        )
        
        db.add(attachment)
        db.commit()
        db.refresh(attachment)
        
        return attachment
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao fazer upload: {str(e)}",
        )


@router.get("/{record_id}/attachments", response_model=List[AttachmentBase])
async def list_attachments(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista anexos de um registro médico"""
    check_record_access(record_id, current_user, db)
    
    attachments = db.query(Attachment).filter(Attachment.record_id == record_id).all()
    return attachments


@router.get("/{record_id}/attachments/{attachment_id}", response_model=AttachmentWithPresignedUrl)
async def get_attachment(
    record_id: int,
    attachment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Obtém detalhes de um anexo com URL de download temporária.
    
    A URL de download (presigned URL) é válida por 1 hora.
    """
    check_record_access(record_id, current_user, db)
    
    attachment = db.query(Attachment).filter(
        Attachment.id == attachment_id,
        Attachment.record_id == record_id,
    ).first()
    
    if not attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anexo não encontrado",
        )
    
    # Gera presigned URL para download
    s3_client = get_s3_client()
    s3_key = get_s3_key_from_url(attachment.file_url)
    
    try:
        download_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': settings.S3_BUCKET,
                'Key': s3_key,
                'ResponseContentDisposition': f'attachment; filename="{attachment.file_name}"',
            },
            ExpiresIn=3600,  # 1 hora
        )
    except ClientError:
        download_url = None
    
    return AttachmentWithPresignedUrl(
        id=attachment.id,
        file_url=attachment.file_url,
        file_name=attachment.file_name,
        mime_type=attachment.mime_type,
        file_size=attachment.file_size,
        created_at=attachment.created_at,
        download_url=download_url,
    )


@router.get("/{record_id}/attachments/{attachment_id}/download")
async def download_attachment(
    record_id: int,
    attachment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Redireciona para download do anexo via presigned URL.
    
    A URL gerada é válida por 1 hora.
    """
    check_record_access(record_id, current_user, db)
    
    attachment = db.query(Attachment).filter(
        Attachment.id == attachment_id,
        Attachment.record_id == record_id,
    ).first()
    
    if not attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anexo não encontrado",
        )
    
    # Gera presigned URL para download
    s3_client = get_s3_client()
    s3_key = get_s3_key_from_url(attachment.file_url)
    
    try:
        download_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': settings.S3_BUCKET,
                'Key': s3_key,
                'ResponseContentDisposition': f'attachment; filename="{attachment.file_name}"',
            },
            ExpiresIn=3600,
        )
        return RedirectResponse(url=download_url)
    except ClientError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao gerar URL de download: {str(e)}",
        )


@router.delete("/{record_id}/attachments/{attachment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_attachment(
    record_id: int,
    attachment_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deleta um anexo"""
    check_record_access(record_id, current_user, db)
    
    attachment = db.query(Attachment).filter(
        Attachment.id == attachment_id,
        Attachment.record_id == record_id,
    ).first()
    
    if not attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Anexo não encontrado",
        )
    
    # Remove do S3/MinIO
    try:
        s3_client = get_s3_client()
        s3_key = get_s3_key_from_url(attachment.file_url)
        s3_client.delete_object(Bucket=settings.S3_BUCKET, Key=s3_key)
    except Exception:
        pass  # Ignora erro se arquivo não existir
    
    # Remove do banco
    db.delete(attachment)
    db.commit()
    
    return None
