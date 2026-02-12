from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class DocumentBase(BaseModel):
    title: str
    document_type: str  # vaccination_card, health_certificate, exam, other
    description: Optional[str] = None
    document_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None


class DocumentCreate(DocumentBase):
    pet_id: int
    file_url: str
    file_name: str
    file_type: Optional[str] = None
    file_size: Optional[int] = None


class DocumentUpdate(BaseModel):
    title: Optional[str] = None
    document_type: Optional[str] = None
    description: Optional[str] = None
    document_date: Optional[datetime] = None
    expiry_date: Optional[datetime] = None


class DocumentResponse(DocumentBase):
    id: int
    pet_id: int
    file_url: str
    file_name: str
    file_type: Optional[str] = None
    file_size: Optional[int] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
