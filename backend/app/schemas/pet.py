from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime


class PetBase(BaseModel):
    name: str
    species: str
    breed: Optional[str] = None
    sex: Optional[str] = None
    birth_date: Optional[date] = None
    weight: Optional[str] = None
    is_castrated: bool = False
    microchip: Optional[str] = None
    photo_url: Optional[str] = None
    notes: Optional[str] = None


class PetCreate(PetBase):
    pass


class PetUpdate(BaseModel):
    name: Optional[str] = None
    species: Optional[str] = None
    breed: Optional[str] = None
    sex: Optional[str] = None
    birth_date: Optional[date] = None
    weight: Optional[str] = None
    is_castrated: Optional[bool] = None
    microchip: Optional[str] = None
    photo_url: Optional[str] = None
    notes: Optional[str] = None


class PetResponse(PetBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

