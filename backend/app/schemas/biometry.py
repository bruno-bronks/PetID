from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List


class SnoutImageUpload(BaseModel):
    """Schema para upload de imagem do focinho"""
    image_base64: str = Field(..., description="Imagem em base64")
    quality_check: bool = Field(default=True, description="Verificar qualidade da imagem")


class BiometryRegisterRequest(BaseModel):
    """Schema para registrar biometria"""
    pet_id: int
    image_base64: str = Field(..., description="Imagem do focinho em base64")


class BiometrySearchRequest(BaseModel):
    """Schema para buscar pet por focinho"""
    image_base64: str = Field(..., description="Imagem do focinho em base64")
    threshold: float = Field(default=0.85, ge=0.5, le=1.0, description="Limiar de similaridade")
    max_results: int = Field(default=5, ge=1, le=20, description="Número máximo de resultados")


class BiometryResponse(BaseModel):
    """Response da biometria registrada"""
    id: int
    pet_id: int
    quality_score: Optional[int]
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class PetSearchResult(BaseModel):
    """Resultado de busca de pet por focinho"""
    pet_id: int
    pet_name: str
    species: str
    breed: Optional[str]
    owner_name: Optional[str]
    owner_phone: Optional[str]  # Mascarado para privacidade
    similarity: float
    has_contact_permission: bool = True


class BiometrySearchResponse(BaseModel):
    """Response da busca por focinho"""
    found: bool
    results: List[PetSearchResult]
    message: str

