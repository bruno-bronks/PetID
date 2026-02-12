from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.core.security import get_current_user
from app.services.biometry_service import BiometryService
from app.schemas.biometry import (
    BiometryRegisterRequest,
    BiometrySearchRequest,
    BiometryResponse,
    BiometrySearchResponse,
    PetSearchResult
)

router = APIRouter()


@router.post("/register", response_model=BiometryResponse, status_code=status.HTTP_201_CREATED)
async def register_snout_biometry(
    data: BiometryRegisterRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Registra a biometria do focinho de um pet.
    
    O pet deve pertencer ao usuário autenticado.
    A imagem deve ser enviada em base64.
    """
    service = BiometryService(db)
    biometry, message = service.register_snout(
        pet_id=data.pet_id,
        image_base64=data.image_base64,
        owner_id=current_user.id
    )
    
    if not biometry:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )
    
    return biometry


@router.post("/search", response_model=BiometrySearchResponse)
async def search_pet_by_snout(
    data: BiometrySearchRequest,
    db: Session = Depends(get_db),
):
    """
    Busca pets por similaridade do focinho.
    
    Este endpoint é público para permitir que qualquer pessoa
    possa encontrar o dono de um pet perdido.
    
    Os dados de contato são parcialmente mascarados por privacidade.
    """
    service = BiometryService(db)
    results = service.search_by_snout(
        image_base64=data.image_base64,
        threshold=data.threshold,
        max_results=data.max_results
    )
    
    if not results:
        return BiometrySearchResponse(
            found=False,
            results=[],
            message="Nenhum pet encontrado com esse focinho. Tente tirar uma foto mais nítida ou com melhor iluminação."
        )
    
    pet_results = [
        PetSearchResult(
            pet_id=r["pet_id"],
            pet_name=r["pet_name"],
            species=r["species"],
            breed=r["breed"],
            owner_name=r["owner_name"],
            owner_phone=r["owner_phone"],
            similarity=r["similarity"],
            has_contact_permission=r["has_contact_permission"]
        )
        for r in results
    ]
    
    return BiometrySearchResponse(
        found=True,
        results=pet_results,
        message=f"Encontrado(s) {len(results)} pet(s) com similaridade acima de {data.threshold * 100:.0f}%"
    )


@router.get("/{pet_id}", response_model=BiometryResponse)
async def get_pet_biometry(
    pet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém a biometria de um pet"""
    from app.models.snout_biometry import SnoutBiometry
    from app.models.pet import Pet
    
    biometry = db.query(SnoutBiometry).join(Pet).filter(
        SnoutBiometry.pet_id == pet_id,
        Pet.owner_id == current_user.id
    ).first()
    
    if not biometry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Biometria não encontrada para este pet"
        )
    
    return biometry


@router.delete("/{pet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_pet_biometry(
    pet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove a biometria de um pet"""
    service = BiometryService(db)
    deleted = service.delete_biometry(pet_id, current_user.id)
    
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Biometria não encontrada"
        )
    
    return None

