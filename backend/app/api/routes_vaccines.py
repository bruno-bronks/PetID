from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.session import get_db
from app.models.user import User
from app.core.security import get_current_user
from app.services.vaccine_service import VaccineService
from app.schemas.vaccine_reminder import (
    VaccineReminderCreate,
    VaccineReminderUpdate,
    VaccineReminderComplete,
    VaccineReminderResponse,
    UpcomingVaccinesResponse
)

router = APIRouter()


@router.post("", response_model=VaccineReminderResponse, status_code=status.HTTP_201_CREATED)
async def create_vaccine_reminder(
    data: VaccineReminderCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Cria um lembrete de vacina para um pet"""
    service = VaccineService(db)
    reminder, message = service.create_reminder(
        pet_id=data.pet_id,
        vaccine_name=data.vaccine_name,
        scheduled_date=data.scheduled_date,
        owner_id=current_user.id,
        notify_days_before=data.notify_days_before,
        notes=data.notes
    )
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    
    return reminder


@router.get("", response_model=List[VaccineReminderResponse])
async def list_vaccine_reminders(
    pet_id: Optional[int] = Query(None, description="Filtrar por pet"),
    include_completed: bool = Query(False, description="Incluir vacinas já aplicadas"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista lembretes de vacinas do usuário"""
    service = VaccineService(db)
    reminders = service.list_reminders(
        owner_id=current_user.id,
        pet_id=pet_id,
        include_completed=include_completed
    )
    return reminders


@router.get("/upcoming", response_model=UpcomingVaccinesResponse)
async def get_upcoming_vaccines(
    days_ahead: int = Query(30, ge=7, le=90, description="Dias à frente para considerar"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Retorna vacinas próximas e atrasadas.
    
    Útil para exibir notificações e alertas no app.
    """
    service = VaccineService(db)
    result = service.get_upcoming_vaccines(
        owner_id=current_user.id,
        days_ahead=days_ahead
    )
    
    return UpcomingVaccinesResponse(
        upcoming=result["upcoming"],
        overdue=result["overdue"],
        total_pending=result["total_pending"]
    )


@router.get("/suggestions/{pet_id}")
async def get_vaccine_suggestions(
    pet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Sugere vacinas baseado na espécie do pet.
    
    Retorna lista de vacinas comuns com seus intervalos padrão.
    """
    service = VaccineService(db)
    suggestions = service.suggest_vaccines(pet_id, current_user.id)
    
    if not suggestions:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado"
        )
    
    return {"suggestions": suggestions}


@router.get("/{reminder_id}", response_model=VaccineReminderResponse)
async def get_vaccine_reminder(
    reminder_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém detalhes de um lembrete"""
    from app.models.vaccine_reminder import VaccineReminder
    from app.models.pet import Pet
    from datetime import date
    
    reminder = db.query(VaccineReminder).join(Pet).filter(
        VaccineReminder.id == reminder_id,
        Pet.owner_id == current_user.id
    ).first()
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lembrete não encontrado"
        )
    
    # Adiciona campos calculados
    today = date.today()
    days_diff = (reminder.scheduled_date - today).days
    reminder.days_until = days_diff
    reminder.is_overdue = days_diff < 0 and not reminder.is_completed
    
    return reminder


@router.patch("/{reminder_id}", response_model=VaccineReminderResponse)
async def update_vaccine_reminder(
    reminder_id: int,
    data: VaccineReminderUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza um lembrete de vacina"""
    service = VaccineService(db)
    reminder, message = service.update_reminder(
        reminder_id=reminder_id,
        owner_id=current_user.id,
        **data.model_dump(exclude_unset=True)
    )
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=message
        )
    
    return reminder


@router.post("/{reminder_id}/complete", response_model=VaccineReminderResponse)
async def complete_vaccine_reminder(
    reminder_id: int,
    data: VaccineReminderComplete,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Marca uma vacina como aplicada.
    
    Opcionalmente pode linkar ao registro médico correspondente.
    """
    service = VaccineService(db)
    reminder, message = service.complete_reminder(
        reminder_id=reminder_id,
        owner_id=current_user.id,
        completed_date=data.completed_date,
        record_id=data.record_id
    )
    
    if not reminder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=message
        )
    
    return reminder


@router.delete("/{reminder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vaccine_reminder(
    reminder_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove um lembrete de vacina"""
    service = VaccineService(db)
    deleted = service.delete_reminder(reminder_id, current_user.id)
    
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Lembrete não encontrado"
        )
    
    return None

