from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from app.db.session import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.medication import Medication, MedicationLog
from app.schemas.medication import (
    MedicationCreate, MedicationUpdate, MedicationResponse,
    MedicationLogCreate, MedicationLogResponse, MedicationResponseWithPet
)
from app.core.security import get_current_user

router = APIRouter()


@router.get("/active", response_model=List[MedicationResponseWithPet])
async def list_all_active_medications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista todos os medicamentos ativos de todos os pets do usuário"""
    medications = db.query(Medication).join(Pet).filter(
        Pet.owner_id == current_user.id,
        Medication.is_active == True
    ).order_by(Medication.start_date.desc()).all()
    
    # Adiciona pet_name manualmente pois o schema espera pet_name
    results = []
    for med in medications:
        resp = MedicationResponseWithPet.model_validate(med)
        resp.pet_name = med.pet.name
        results.append(resp)
        
    return results


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


@router.post("/{pet_id}/medications", response_model=MedicationResponse, status_code=status.HTTP_201_CREATED)
async def create_medication(
    pet_id: int,
    data: MedicationCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Adiciona um medicamento ao pet"""
    check_pet_access(pet_id, current_user, db)
    
    medication = Medication(
        pet_id=pet_id,
        name=data.name,
        dosage=data.dosage,
        frequency=data.frequency,
        instructions=data.instructions,
        start_date=data.start_date,
        end_date=data.end_date,
        reminder_enabled=data.reminder_enabled,
        reminder_times=data.reminder_times,
        notes=data.notes,
        prescribed_by=data.prescribed_by,
    )
    
    db.add(medication)
    db.commit()
    db.refresh(medication)
    
    return medication


@router.get("/{pet_id}/medications", response_model=List[MedicationResponse])
async def list_medications(
    pet_id: int,
    active_only: bool = Query(False, description="Filtrar apenas medicamentos ativos"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista medicamentos do pet"""
    check_pet_access(pet_id, current_user, db)
    
    query = db.query(Medication).filter(Medication.pet_id == pet_id)
    
    if active_only:
        query = query.filter(Medication.is_active == True)
    
    medications = query.order_by(Medication.is_active.desc(), Medication.start_date.desc()).all()
    return medications


@router.get("/{pet_id}/medications/{medication_id}", response_model=MedicationResponse)
async def get_medication(
    pet_id: int,
    medication_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém detalhes de um medicamento"""
    check_pet_access(pet_id, current_user, db)
    
    medication = db.query(Medication).filter(
        Medication.id == medication_id,
        Medication.pet_id == pet_id,
    ).first()
    
    if not medication:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicamento não encontrado",
        )
    
    return medication


@router.patch("/{pet_id}/medications/{medication_id}", response_model=MedicationResponse)
async def update_medication(
    pet_id: int,
    medication_id: int,
    data: MedicationUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza dados de um medicamento"""
    check_pet_access(pet_id, current_user, db)
    
    medication = db.query(Medication).filter(
        Medication.id == medication_id,
        Medication.pet_id == pet_id,
    ).first()
    
    if not medication:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicamento não encontrado",
        )
    
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(medication, field, value)
    
    db.commit()
    db.refresh(medication)
    
    return medication


@router.delete("/{pet_id}/medications/{medication_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medication(
    pet_id: int,
    medication_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove um medicamento"""
    check_pet_access(pet_id, current_user, db)
    
    medication = db.query(Medication).filter(
        Medication.id == medication_id,
        Medication.pet_id == pet_id,
    ).first()
    
    if not medication:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicamento não encontrado",
        )
    
    db.delete(medication)
    db.commit()
    
    return None


# Rotas para logs de administração
@router.post("/{pet_id}/medications/{medication_id}/logs", response_model=MedicationLogResponse, status_code=status.HTTP_201_CREATED)
async def log_medication(
    pet_id: int,
    medication_id: int,
    data: MedicationLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Registra administração de medicamento"""
    check_pet_access(pet_id, current_user, db)
    
    medication = db.query(Medication).filter(
        Medication.id == medication_id,
        Medication.pet_id == pet_id,
    ).first()
    
    if not medication:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicamento não encontrado",
        )
    
    log = MedicationLog(
        medication_id=medication_id,
        administered_at=data.administered_at,
        administered_by=data.administered_by,
        notes=data.notes,
        skipped=data.skipped,
        skip_reason=data.skip_reason,
    )
    
    db.add(log)
    db.commit()
    db.refresh(log)
    
    return log


@router.get("/{pet_id}/medications/{medication_id}/logs", response_model=List[MedicationLogResponse])
async def list_medication_logs(
    pet_id: int,
    medication_id: int,
    limit: int = Query(50, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista histórico de administração de um medicamento"""
    check_pet_access(pet_id, current_user, db)
    
    medication = db.query(Medication).filter(
        Medication.id == medication_id,
        Medication.pet_id == pet_id,
    ).first()
    
    if not medication:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Medicamento não encontrado",
        )
    
    logs = db.query(MedicationLog).filter(
        MedicationLog.medication_id == medication_id
    ).order_by(MedicationLog.administered_at.desc()).limit(limit).all()
    
    return logs
