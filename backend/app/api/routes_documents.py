from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import boto3
from botocore.config import Config
from botocore.exceptions import ClientError
import uuid
from datetime import datetime
from app.db.session import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.document import PetDocument
from app.schemas.document import DocumentCreate, DocumentUpdate, DocumentResponse
from app.core.security import get_current_user
from app.core.config import settings

router = APIRouter()


@router.post("/{pet_id}/photo", status_code=status.HTTP_200_OK)
async def upload_pet_photo(
    pet_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload ou substituição da foto do pet"""
    pet = check_pet_access(pet_id, current_user, db)

    # Validar tipo de imagem
    allowed_types = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Use uma imagem JPEG, PNG ou WebP.",
        )

    s3_client = get_s3_client()
    bucket = settings.S3_BUCKET

    # Garante que o bucket existe
    try:
        s3_client.head_bucket(Bucket=bucket)
    except ClientError:
        s3_client.create_bucket(Bucket=bucket)

    # Remove foto antiga se existir
    if pet.photo_url:
        try:
            old_key = pet.photo_url.split(f"{bucket}/")[-1].split("?")[0]
            s3_client.delete_object(Bucket=bucket, Key=old_key)
        except Exception:
            pass

    # Upload nova foto
    file_ext = (file.filename or "photo").rsplit(".", 1)[-1].lower()
    s3_key = f"photos/{pet_id}/{uuid.uuid4()}.{file_ext}"
    try:
        file_content = await file.read()
        s3_client.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=file_content,
            ContentType=file.content_type,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao fazer upload: {str(e)}",
        )

    # Gera presigned URL (24h) para usar como photo_url
    try:
        photo_url = s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": bucket, "Key": s3_key},
            ExpiresIn=86400,
        )
    except Exception:
        photo_url = f"{settings.S3_ENDPOINT}/{bucket}/{s3_key}"

    # Persiste a chave S3 no pet (usando a chave, não URL assinada)
    # Armazenamos a chave para gerar presigned URL sob demanda
    pet.photo_url = f"{settings.S3_ENDPOINT}/{bucket}/{s3_key}"
    db.commit()

    return {"photo_url": photo_url, "s3_key": s3_key}



def get_s3_client():
    """Cria cliente S3 (MinIO)"""
    return boto3.client(
        's3',
        endpoint_url=settings.S3_ENDPOINT,
        aws_access_key_id=settings.S3_ACCESS_KEY,
        aws_secret_access_key=settings.S3_SECRET_KEY,
        config=Config(signature_version='s3v4'),
        region_name=settings.S3_REGION,
    )


def check_pet_access(pet_id: int, user: User, db: Session) -> Pet:
    """Verifica se o usuário tem acesso ao pet"""
    pet = db.query(Pet).filter(Pet.id == pet_id).first()
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado",
        )
    
    if pet.owner_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar este pet",
        )
    
    return pet


@router.post("/{pet_id}/documents", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
async def upload_document(
    pet_id: int,
    file: UploadFile = File(...),
    title: str = Form(...),
    document_type: str = Form(...),
    description: Optional[str] = Form(None),
    document_date: Optional[str] = Form(None),
    expiry_date: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Upload de documento do pet"""
    check_pet_access(pet_id, current_user, db)
    
    # Validar tipo de arquivo
    allowed_types = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg']
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de arquivo não permitido. Use: {', '.join(allowed_types)}",
        )
    
    # Gerar nome único
    file_ext = file.filename.split('.')[-1] if '.' in file.filename else 'pdf'
    unique_filename = f"documents/{pet_id}/{uuid.uuid4()}.{file_ext}"
    
    # Upload para S3/MinIO
    s3_client = get_s3_client()
    try:
        file_content = await file.read()
        s3_client.put_object(
            Bucket=settings.S3_BUCKET,
            Key=unique_filename,
            Body=file_content,
            ContentType=file.content_type,
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao fazer upload: {str(e)}",
        )
    
    # URL do arquivo
    file_url = f"{settings.S3_ENDPOINT}/{settings.S3_BUCKET}/{unique_filename}"
    
    # Parse datas
    parsed_doc_date = None
    parsed_expiry_date = None
    if document_date:
        try:
            parsed_doc_date = datetime.fromisoformat(document_date.replace('Z', '+00:00'))
        except:
            pass
    if expiry_date:
        try:
            parsed_expiry_date = datetime.fromisoformat(expiry_date.replace('Z', '+00:00'))
        except:
            pass
    
    # Criar registro no banco
    document = PetDocument(
        pet_id=pet_id,
        title=title,
        document_type=document_type,
        description=description,
        file_url=file_url,
        file_name=file.filename,
        file_type=file.content_type,
        file_size=len(file_content),
        document_date=parsed_doc_date,
        expiry_date=parsed_expiry_date,
    )
    
    db.add(document)
    db.commit()
    db.refresh(document)
    
    return document


@router.get("/{pet_id}/documents", response_model=List[DocumentResponse])
async def list_documents(
    pet_id: int,
    document_type: Optional[str] = Query(None, description="Filtrar por tipo"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista documentos do pet"""
    check_pet_access(pet_id, current_user, db)
    
    query = db.query(PetDocument).filter(PetDocument.pet_id == pet_id)
    
    if document_type:
        query = query.filter(PetDocument.document_type == document_type)
    
    documents = query.order_by(PetDocument.created_at.desc()).all()
    return documents


@router.get("/{pet_id}/documents/{document_id}", response_model=DocumentResponse)
async def get_document(
    pet_id: int,
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém detalhes de um documento"""
    check_pet_access(pet_id, current_user, db)
    
    document = db.query(PetDocument).filter(
        PetDocument.id == document_id,
        PetDocument.pet_id == pet_id,
    ).first()
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado",
        )
    
    return document


@router.get("/{pet_id}/documents/{document_id}/download")
async def download_document(
    pet_id: int,
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Gera URL temporária para download do documento"""
    check_pet_access(pet_id, current_user, db)
    
    document = db.query(PetDocument).filter(
        PetDocument.id == document_id,
        PetDocument.pet_id == pet_id,
    ).first()
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado",
        )
    
    # Extrair key do URL
    key = document.file_url.split(f"{settings.S3_BUCKET}/")[-1]
    
    # Gerar URL presigned
    s3_client = get_s3_client()
    try:
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': settings.S3_BUCKET, 'Key': key},
            ExpiresIn=3600,  # 1 hora
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao gerar URL: {str(e)}",
        )
    
    return {"download_url": presigned_url, "expires_in": 3600}


@router.patch("/{pet_id}/documents/{document_id}", response_model=DocumentResponse)
async def update_document(
    pet_id: int,
    document_id: int,
    data: DocumentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza metadados de um documento"""
    check_pet_access(pet_id, current_user, db)
    
    document = db.query(PetDocument).filter(
        PetDocument.id == document_id,
        PetDocument.pet_id == pet_id,
    ).first()
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado",
        )
    
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(document, field, value)
    
    db.commit()
    db.refresh(document)
    
    return document


@router.delete("/{pet_id}/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    pet_id: int,
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove um documento"""
    check_pet_access(pet_id, current_user, db)
    
    document = db.query(PetDocument).filter(
        PetDocument.id == document_id,
        PetDocument.pet_id == pet_id,
    ).first()
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Documento não encontrado",
        )
    
    # Deletar arquivo do S3
    key = document.file_url.split(f"{settings.S3_BUCKET}/")[-1]
    s3_client = get_s3_client()
    try:
        s3_client.delete_object(Bucket=settings.S3_BUCKET, Key=key)
    except:
        pass  # Ignora erro de deleção do S3
    
    db.delete(document)
    db.commit()
    
    return None
