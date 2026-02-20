from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime, date


class MedicationBase(BaseModel):
    name: str
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    instructions: Optional[str] = None
    start_date: date
    end_date: Optional[date] = None
    reminder_enabled: bool = True
    reminder_times: Optional[str] = None
    notes: Optional[str] = None
    prescribed_by: Optional[str] = None


class MedicationCreate(MedicationBase):
    pet_id: int


class MedicationUpdate(BaseModel):
    name: Optional[str] = None
    dosage: Optional[str] = None
    frequency: Optional[str] = None
    instructions: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    reminder_enabled: Optional[bool] = None
    reminder_times: Optional[str] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None
    prescribed_by: Optional[str] = None


class MedicationResponse(MedicationBase):
    id: int
    pet_id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class MedicationResponseWithPet(MedicationResponse):
    pet_name: Optional[str] = None


class MedicationLogCreate(BaseModel):
    administered_at: datetime
    administered_by: Optional[str] = None
    notes: Optional[str] = None
    skipped: bool = False
    skip_reason: Optional[str] = None


class MedicationLogResponse(BaseModel):
    id: int
    medication_id: int
    administered_at: datetime
    administered_by: Optional[str] = None
    notes: Optional[str] = None
    skipped: bool
    skip_reason: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
