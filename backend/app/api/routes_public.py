from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from math import radians, cos, sin, asin, sqrt
from datetime import datetime
from app.db.session import get_db
from app.models.pet import Pet
from app.models.user import User
from app.models.lost_pet import LostPetReport
from app.models.snout_biometry import SnoutBiometry
from app.schemas.lost_pet import (
    LostPetReportCreate,
    FoundPetReportCreate,
    LostPetReportUpdate,
    LostPetReportResponse,
    NearbyReportsRequest,
    PetPublicProfile
)
from app.core.security import get_current_user

router = APIRouter()


def haversine(lon1, lat1, lon2, lat2):
    """Calcula distância em km entre dois pontos"""
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    km = 6371 * c
    return km


def mask_phone(phone: str) -> str:
    """Mascara telefone para privacidade"""
    if not phone or len(phone) < 4:
        return "****"
    return phone[:3] + "*" * (len(phone) - 5) + phone[-2:]


from app.models.record import MedicalRecord
from app.models.medication import Medication

# ==================== PERFIL PÚBLICO (QR CODE) ====================


class PetIdentifiedProfile(PetPublicProfile):
    """Perfil do pet identificado por biometria (com telefone completo)"""
    pass


@router.get("/pet/{pet_id}/identified", response_model=PetIdentifiedProfile)
async def get_identified_pet_profile(
    pet_id: int,
    db: Session = Depends(get_db),
):
    """
    Obtém perfil completo de um pet identificado por biometria.

    Este endpoint retorna o telefone completo do tutor para permitir
    contato direto quando alguém identifica um pet pelo focinho.
    Usado principalmente para ajudar a reunir pets perdidos.
    """
    pet = db.query(Pet).filter(Pet.id == pet_id).first()

    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado"
        )

    # Verifica se tem reporte de perdido ativo
    is_lost = db.query(LostPetReport).filter(
        LostPetReport.pet_id == pet_id,
        LostPetReport.report_type == 'lost',
        LostPetReport.status == 'active'
    ).first() is not None

    # Verifica se tem biometria
    has_biometry = db.query(SnoutBiometry).filter(
        SnoutBiometry.pet_id == pet_id,
        SnoutBiometry.is_active == True
    ).first() is not None

    # Busca vacinas recentes (últimas 5)
    vaccines = db.query(MedicalRecord).filter(
        MedicalRecord.pet_id == pet_id,
        MedicalRecord.type == 'vaccine'
    ).order_by(MedicalRecord.event_date.desc()).limit(5).all()

    # Busca medicamentos ativos
    active_meds = db.query(Medication).filter(
        Medication.pet_id == pet_id,
        Medication.is_active == True
    ).all()

    # Busca dados do dono - TELEFONE COMPLETO para identificação por biometria
    owner = db.query(User).filter(User.id == pet.owner_id).first()

    return PetIdentifiedProfile(
        id=pet.id,
        name=pet.name,
        species=pet.species,
        breed=pet.breed,
        sex=pet.sex,
        photo_url=pet.photo_url,
        is_lost=is_lost,
        owner_name=owner.full_name if owner else None,
        owner_phone=owner.phone if owner else None,  # Telefone COMPLETO
        has_biometry=has_biometry,
        vaccines=[
            {"title": v.title, "event_date": v.event_date}
            for v in vaccines
        ],
        active_medications=[
            {
                "name": m.name,
                "dosage": m.dosage,
                "frequency": m.frequency,
                "is_active": m.is_active
            }
            for m in active_meds
        ]
    )


@router.get("/pet/{pet_id}", response_model=PetPublicProfile)
async def get_public_pet_profile(
    pet_id: int,
    db: Session = Depends(get_db),
):
    """
    Obtém perfil público de um pet (para QR Code).
    
    Não requer autenticação - qualquer pessoa pode ver.
    Dados sensíveis são mascarados.
    """
    pet = db.query(Pet).filter(Pet.id == pet_id).first()
    
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado"
        )
    
    # Verifica se tem reporte de perdido ativo
    is_lost = db.query(LostPetReport).filter(
        LostPetReport.pet_id == pet_id,
        LostPetReport.report_type == 'lost',
        LostPetReport.status == 'active'
    ).first() is not None
    
    # Verifica se tem biometria
    has_biometry = db.query(SnoutBiometry).filter(
        SnoutBiometry.pet_id == pet_id,
        SnoutBiometry.is_active == True
    ).first() is not None
    
    # Busca vacinas recentes (últimas 5)
    vaccines = db.query(MedicalRecord).filter(
        MedicalRecord.pet_id == pet_id,
        MedicalRecord.type == 'vaccine'
    ).order_by(MedicalRecord.event_date.desc()).limit(5).all()
    
    # Busca medicamentos ativos
    active_meds = db.query(Medication).filter(
        Medication.pet_id == pet_id,
        Medication.is_active == True
    ).all()
    
    # Busca dados do dono
    owner = db.query(User).filter(User.id == pet.owner_id).first()
    
    return PetPublicProfile(
        id=pet.id,
        name=pet.name,
        species=pet.species,
        breed=pet.breed,
        sex=pet.sex,
        photo_url=pet.photo_url,
        is_lost=is_lost,
        owner_name=owner.full_name if owner else None,
        owner_phone=mask_phone(owner.phone) if owner and owner.phone else None,
        has_biometry=has_biometry,
        vaccines=[
            {"title": v.title, "event_date": v.event_date}
            for v in vaccines
        ],
        active_medications=[
            {
                "name": m.name,
                "dosage": m.dosage,
                "frequency": m.frequency,
                "is_active": m.is_active
            }
            for m in active_meds
        ]
    )


# ==================== PETS PERDIDOS/ENCONTRADOS ====================

@router.post("/lost-pets/report", response_model=LostPetReportResponse, status_code=status.HTTP_201_CREATED)
async def create_lost_pet_report(
    data: LostPetReportCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Reportar que seu pet está perdido"""
    # Verifica se o pet pertence ao usuário
    pet = db.query(Pet).filter(
        Pet.id == data.pet_id,
        Pet.owner_id == current_user.id
    ).first()
    
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado"
        )
    
    # Verifica se já tem reporte ativo
    existing = db.query(LostPetReport).filter(
        LostPetReport.pet_id == data.pet_id,
        LostPetReport.status == 'active'
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Já existe um reporte ativo para este pet"
        )
    
    report = LostPetReport(
        pet_id=data.pet_id,
        reporter_id=current_user.id,
        report_type='lost',
        latitude=data.latitude,
        longitude=data.longitude,
        address=data.address,
        city=data.city,
        description=data.description,
        contact_phone=data.contact_phone or current_user.phone,
        contact_visible=data.contact_visible,
        event_date=data.event_date,
        status='active'
    )
    
    db.add(report)
    db.commit()
    db.refresh(report)
    
    return _build_report_response(report, pet)


@router.post("/lost-pets/found", response_model=LostPetReportResponse, status_code=status.HTTP_201_CREATED)
async def create_found_pet_report(
    data: FoundPetReportCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Reportar que encontrou um pet"""
    pet = None
    if data.pet_id:
        pet = db.query(Pet).filter(Pet.id == data.pet_id).first()
    
    report = LostPetReport(
        pet_id=data.pet_id,
        reporter_id=current_user.id,
        report_type='found',
        latitude=data.latitude,
        longitude=data.longitude,
        address=data.address,
        city=data.city,
        description=data.description,
        contact_phone=data.contact_phone or current_user.phone,
        contact_visible=data.contact_visible,
        event_date=data.event_date,
        found_species=data.found_species,
        found_breed=data.found_breed,
        found_color=data.found_color,
        status='active'
    )
    
    db.add(report)
    db.commit()
    db.refresh(report)
    
    return _build_report_response(report, pet)


@router.get("/lost-pets/nearby", response_model=List[LostPetReportResponse])
async def get_nearby_lost_pets(
    latitude: float = Query(..., description="Latitude atual"),
    longitude: float = Query(..., description="Longitude atual"),
    radius_km: float = Query(10, ge=1, le=5000, description="Raio de busca em km"),
    report_type: Optional[str] = Query(None, description="Filtrar por tipo: lost, found"),
    db: Session = Depends(get_db),
):
    """
    Busca reportes de pets perdidos/encontrados próximos.
    
    Não requer autenticação para permitir que qualquer pessoa ajude.
    """
    query = db.query(LostPetReport).filter(
        LostPetReport.status == 'active'
    )
    
    if report_type:
        query = query.filter(LostPetReport.report_type == report_type)
    
    reports = query.all()
    
    # Filtra por distância e adiciona informações
    results = []
    for report in reports:
        distance = haversine(longitude, latitude, report.longitude, report.latitude)
        if distance <= radius_km:
            pet = None
            if report.pet_id:
                pet = db.query(Pet).filter(Pet.id == report.pet_id).first()
            
            response = _build_report_response(report, pet)
            response.distance_km = round(distance, 2)
            results.append(response)
    
    # Ordena por distância
    results.sort(key=lambda x: x.distance_km or 999)
    
    return results


@router.get("/lost-pets/my-reports", response_model=List[LostPetReportResponse])
async def get_my_reports(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Lista reportes criados pelo usuário"""
    reports = db.query(LostPetReport).filter(
        LostPetReport.reporter_id == current_user.id
    ).order_by(LostPetReport.created_at.desc()).all()
    
    results = []
    for report in reports:
        pet = None
        if report.pet_id:
            pet = db.query(Pet).filter(Pet.id == report.pet_id).first()
        results.append(_build_report_response(report, pet))
    
    return results


@router.patch("/lost-pets/{report_id}/resolve")
async def resolve_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Marca reporte como resolvido (pet encontrado)"""
    report = db.query(LostPetReport).filter(
        LostPetReport.id == report_id,
        LostPetReport.reporter_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte não encontrado"
        )
    
    report.status = 'resolved'
    report.resolved_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Reporte marcado como resolvido!"}


@router.delete("/lost-pets/{report_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_report(
    report_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Remove um reporte"""
    report = db.query(LostPetReport).filter(
        LostPetReport.id == report_id,
        LostPetReport.reporter_id == current_user.id
    ).first()
    
    if not report:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reporte não encontrado"
        )
    
    db.delete(report)
    db.commit()
    return None


def _build_report_response(report: LostPetReport, pet: Pet = None) -> LostPetReportResponse:
    """Constrói response do reporte"""
    return LostPetReportResponse(
        id=report.id,
        pet_id=report.pet_id,
        reporter_id=report.reporter_id,
        report_type=report.report_type,
        status=report.status,
        latitude=report.latitude,
        longitude=report.longitude,
        address=report.address,
        city=report.city,
        description=report.description,
        contact_phone=report.contact_phone if report.contact_visible else mask_phone(report.contact_phone),
        contact_visible=report.contact_visible,
        event_date=report.event_date,
        created_at=report.created_at,
        pet_name=pet.name if pet else None,
        pet_species=pet.species if pet else report.found_species,
        pet_breed=pet.breed if pet else report.found_breed,
        pet_photo_url=pet.photo_url if pet else report.found_photo_url,
        found_species=report.found_species,
        found_breed=report.found_breed,
        found_color=report.found_color,
        found_photo_url=report.found_photo_url,
    )
