from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from app.db.session import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.record import MedicalRecord
from app.models.vaccine_reminder import VaccineReminder
from app.schemas.record import MedicalRecordCreate, MedicalRecordUpdate, MedicalRecordResponse
from app.core.security import get_current_user

router = APIRouter()


def check_pet_access(pet_id: int, user: User, db: Session) -> Pet:
    """Verifica se o usuário tem acesso ao pet"""
    pet = db.query(Pet).filter(Pet.id == pet_id).first()
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado",
        )
    
    # Verifica se é o dono
    if pet.owner_id != user.id:
        # TODO: Verificar permissões compartilhadas
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar este pet",
        )
    
    return pet


@router.post("/{pet_id}/records", response_model=MedicalRecordResponse, status_code=status.HTTP_201_CREATED)
async def create_record(
    pet_id: int,
    record_data: MedicalRecordCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cria um novo registro médico"""
    # Verifica acesso ao pet
    check_pet_access(pet_id, current_user, db)
    
    # Garante que pet_id do body bate com o da URL
    record_data.pet_id = pet_id
    
    new_record = MedicalRecord(**record_data.model_dump())
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    # Se for vacina, cria automaticamente um VaccineReminder
    if record_data.type == 'vaccine':
        today = date.today()
        is_future = record_data.event_date > today
        
        reminder = VaccineReminder(
            pet_id=pet_id,
            vaccine_name=record_data.title,
            scheduled_date=record_data.event_date,
            is_completed=not is_future,  # Completa se data passou
            completed_date=record_data.event_date if not is_future else None,
            record_id=new_record.id,
            notes=record_data.notes,
        )
        db.add(reminder)
        db.commit()
    
    return new_record


@router.get("/{pet_id}/records", response_model=List[MedicalRecordResponse])
async def list_records(
    pet_id: int,
    record_type: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista registros médicos de um pet"""
    # Verifica acesso ao pet
    check_pet_access(pet_id, current_user, db)
    
    query = db.query(MedicalRecord).filter(MedicalRecord.pet_id == pet_id)
    
    if record_type:
        query = query.filter(MedicalRecord.type == record_type)
    if from_date:
        query = query.filter(MedicalRecord.event_date >= from_date)
    if to_date:
        query = query.filter(MedicalRecord.event_date <= to_date)
    
    records = query.order_by(MedicalRecord.event_date.desc()).all()
    return records


@router.get("/{pet_id}/records/{record_id}", response_model=MedicalRecordResponse)
async def get_record(
    pet_id: int,
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém um registro médico específico"""
    # Verifica acesso ao pet
    check_pet_access(pet_id, current_user, db)
    
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.pet_id == pet_id,
    ).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro não encontrado",
        )
    
    return record


@router.patch("/{pet_id}/records/{record_id}", response_model=MedicalRecordResponse)
async def update_record(
    pet_id: int,
    record_id: int,
    record_data: MedicalRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza um registro médico"""
    # Verifica acesso ao pet
    check_pet_access(pet_id, current_user, db)
    
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.pet_id == pet_id,
    ).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro não encontrado",
        )
    
    # Atualiza apenas campos fornecidos
    update_data = record_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(record, field, value)
    
    db.commit()
    db.refresh(record)
    
    return record


@router.delete("/{pet_id}/records/{record_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_record(
    pet_id: int,
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deleta um registro médico"""
    # Verifica acesso ao pet
    check_pet_access(pet_id, current_user, db)
    
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id,
        MedicalRecord.pet_id == pet_id,
    ).first()
    
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Registro não encontrado",
        )
    
    db.delete(record)
    db.commit()
    
    return None

