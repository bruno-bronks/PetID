from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import date, datetime


class AttachmentBase(BaseModel):
    id: int
    file_url: str
    file_name: str
    mime_type: Optional[str] = None
    file_size: Optional[int] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


class MedicalRecordBase(BaseModel):
    type: str
    title: str
    notes: Optional[str] = None
    event_date: date
    extra_data: Optional[Dict[str, Any]] = None


class MedicalRecordCreate(MedicalRecordBase):
    pet_id: int


class MedicalRecordUpdate(BaseModel):
    type: Optional[str] = None
    title: Optional[str] = None
    notes: Optional[str] = None
    event_date: Optional[date] = None
    extra_data: Optional[Dict[str, Any]] = None


class MedicalRecordResponse(MedicalRecordBase):
    id: int
    pet_id: int
    created_at: datetime
    updated_at: datetime
    attachments: List[AttachmentBase] = []
    
    class Config:
        from_attributes = True

