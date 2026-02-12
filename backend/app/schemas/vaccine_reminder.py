from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List


class VaccineReminderCreate(BaseModel):
    """Schema para criar lembrete de vacina"""
    pet_id: int
    vaccine_name: str
    scheduled_date: date
    notify_days_before: int = Field(default=7, ge=1, le=30)
    notes: Optional[str] = None


class VaccineReminderUpdate(BaseModel):
    """Schema para atualizar lembrete"""
    vaccine_name: Optional[str] = None
    scheduled_date: Optional[date] = None
    notify_days_before: Optional[int] = Field(default=None, ge=1, le=30)
    notes: Optional[str] = None


class VaccineReminderComplete(BaseModel):
    """Schema para marcar vacina como aplicada"""
    completed_date: date
    record_id: Optional[int] = None  # Link opcional para prontuário


class VaccineReminderResponse(BaseModel):
    """Response do lembrete"""
    id: int
    pet_id: int
    vaccine_name: str
    scheduled_date: date
    is_completed: bool
    completed_date: Optional[date]
    record_id: Optional[int]
    notify_days_before: int
    notes: Optional[str]
    created_at: datetime
    days_until: Optional[int] = None  # Calculado dinamicamente
    is_overdue: bool = False  # Calculado dinamicamente
    
    class Config:
        from_attributes = True


class UpcomingVaccinesResponse(BaseModel):
    """Response para vacinas pendentes"""
    upcoming: List[VaccineReminderResponse]
    overdue: List[VaccineReminderResponse]
    total_pending: int

