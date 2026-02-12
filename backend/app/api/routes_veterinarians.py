from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.db.session import get_db
from app.models.user import User
from app.models.pet import Pet
from app.models.veterinarian import Veterinarian
from app.schemas.veterinarian import VeterinarianCreate, VeterinarianUpdate, VeterinarianResponse
from app.core.security import get_current_user

router = APIRouter()


def check_pet_access(pet_id: int, user: User, db: Session) -> Pet:
    """Verifica se o usuário tem acesso ao pet"""
    pet = db.query(Pet).filter(Pet.id == pet_id).first()
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado",
        )
    
    if pet.owner_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sem permissão para acessar este pet",
        )
    
    return pet


@router.post("/{pet_id}/veterinarians", response_model=VeterinarianResponse, status_code=status.HTTP_201_CREATED)
async def create_veterinarian(
    pet_id: int,
    data: VeterinarianCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Adiciona um contato de veterinário ao pet"""
    check_pet_access(pet_id, current_user, db)
    
    vet = Veterinarian(
        pet_id=pet_id,
        name=data.name,
        clinic_name=data.clinic_name,
        phone=data.phone,
        email=data.email,
        address=data.address,
        specialty=data.specialty,
        notes=data.notes,
    )
    
    db.add(vet)
    db.commit()
    db.refresh(vet)
    
    return vet


@router.get("/{pet_id}/veterinarians", response_model=List[VeterinarianResponse])
async def list_veterinarians(
    pet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista veterinários do pet"""
    check_pet_access(pet_id, current_user, db)
    
    vets = db.query(Veterinarian).filter(Veterinarian.pet_id == pet_id).all()
    return vets


@router.get("/{pet_id}/veterinarians/{vet_id}", response_model=VeterinarianResponse)
async def get_veterinarian(
    pet_id: int,
    vet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Obtém detalhes de um veterinário"""
    check_pet_access(pet_id, current_user, db)
    
    vet = db.query(Veterinarian).filter(
        Veterinarian.id == vet_id,
        Veterinarian.pet_id == pet_id,
    ).first()
    
    if not vet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinário não encontrado",
        )
    
    return vet


@router.patch("/{pet_id}/veterinarians/{vet_id}", response_model=VeterinarianResponse)
async def update_veterinarian(
    pet_id: int,
    vet_id: int,
    data: VeterinarianUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza dados de um veterinário"""
    check_pet_access(pet_id, current_user, db)
    
    vet = db.query(Veterinarian).filter(
        Veterinarian.id == vet_id,
        Veterinarian.pet_id == pet_id,
    ).first()
    
    if not vet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinário não encontrado",
        )
    
    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(vet, field, value)
    
    db.commit()
    db.refresh(vet)
    
    return vet


@router.delete("/{pet_id}/veterinarians/{vet_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_veterinarian(
    pet_id: int,
    vet_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove um veterinário"""
    check_pet_access(pet_id, current_user, db)
    
    vet = db.query(Veterinarian).filter(
        Veterinarian.id == vet_id,
        Veterinarian.pet_id == pet_id,
    ).first()
    
    if not vet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Veterinário não encontrado",
        )
    
    db.delete(vet)
    db.commit()
    
    return None
