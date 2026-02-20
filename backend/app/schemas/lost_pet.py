from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List


class LostPetReportCreate(BaseModel):
    """Criar reporte de pet perdido"""
    pet_id: int
    report_type: str = "lost"  # 'lost'
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None
    description: Optional[str] = None
    contact_phone: Optional[str] = None
    contact_visible: bool = True
    event_date: date


class FoundPetReportCreate(BaseModel):
    """Criar reporte de pet encontrado"""
    report_type: str = "found"  # 'found'
    latitude: float
    longitude: float
    address: Optional[str] = None
    city: Optional[str] = None
    description: Optional[str] = None
    contact_phone: Optional[str] = None
    contact_visible: bool = True
    event_date: date
    # Dados do pet encontrado
    found_species: str  # 'dog' ou 'cat'
    found_breed: Optional[str] = None
    found_color: Optional[str] = None
    pet_id: Optional[int] = None  # Se identificou pelo focinho


class LostPetReportUpdate(BaseModel):
    """Atualizar reporte"""
    status: Optional[str] = None
    description: Optional[str] = None
    contact_phone: Optional[str] = None
    contact_visible: Optional[bool] = None


class LostPetReportResponse(BaseModel):
    """Response do reporte"""
    id: int
    pet_id: Optional[int]
    reporter_id: int
    report_type: str
    status: str
    latitude: float
    longitude: float
    address: Optional[str]
    city: Optional[str]
    description: Optional[str]
    contact_phone: Optional[str]
    contact_visible: bool
    event_date: date
    created_at: datetime
    # Dados do pet (se vinculado)
    pet_name: Optional[str] = None
    pet_species: Optional[str] = None
    pet_breed: Optional[str] = None
    pet_photo_url: Optional[str] = None
    # Dados do pet encontrado (se não vinculado)
    found_species: Optional[str] = None
    found_breed: Optional[str] = None
    found_color: Optional[str] = None
    found_photo_url: Optional[str] = None
    # Distância (calculada)
    distance_km: Optional[float] = None
    
    class Config:
        from_attributes = True


class NearbyReportsRequest(BaseModel):
    """Request para buscar reportes próximos"""
    latitude: float
    longitude: float
    radius_km: float = Field(default=10, ge=1, le=100)
    report_type: Optional[str] = None  # 'lost', 'found', ou None para ambos


class VaccinePublic(BaseModel):
    title: str
    event_date: date

    class Config:
        from_attributes = True


class MedicationPublic(BaseModel):
    name: str
    dosage: Optional[str]
    frequency: Optional[str]
    is_active: bool

    class Config:
        from_attributes = True


class PetPublicProfile(BaseModel):
    """Perfil público do pet (para QR Code)"""
    id: int
    name: str
    species: str
    breed: Optional[str]
    sex: Optional[str]
    photo_url: Optional[str]
    is_lost: bool = False
    owner_name: Optional[str]
    owner_phone: Optional[str]  # Mascarado
    has_biometry: bool = False
    vaccines: List[VaccinePublic] = []
    active_medications: List[MedicationPublic] = []
    
    class Config:
        from_attributes = True
