from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class VeterinarianBase(BaseModel):
    name: str
    clinic_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    specialty: Optional[str] = None
    notes: Optional[str] = None


class VeterinarianCreate(VeterinarianBase):
    pet_id: int


class VeterinarianUpdate(BaseModel):
    name: Optional[str] = None
    clinic_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    specialty: Optional[str] = None
    notes: Optional[str] = None


class VeterinarianResponse(VeterinarianBase):
    id: int
    pet_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
