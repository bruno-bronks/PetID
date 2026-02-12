from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date
from pydantic import BaseModel
from app.db.session import get_db
from app.models.user import User
from app.models.audit_log import AuditLog
from app.core.security import get_current_user

router = APIRouter()


class AuditLogResponse(BaseModel):
    id: int
    user_id: Optional[int]
    action: str
    resource_type: Optional[str]
    resource_id: Optional[int]
    details: Optional[dict]
    ip_address: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class AuditLogListResponse(BaseModel):
    total: int
    page: int
    per_page: int
    logs: List[AuditLogResponse]


@router.get("/my-activity", response_model=AuditLogListResponse)
async def get_my_activity(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    action: Optional[str] = None,
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lista atividades do usuário atual.
    
    Útil para o usuário ver seu histórico de ações.
    """
    query = db.query(AuditLog).filter(AuditLog.user_id == current_user.id)
    
    if action:
        query = query.filter(AuditLog.action == action)
    if from_date:
        query = query.filter(AuditLog.created_at >= datetime.combine(from_date, datetime.min.time()))
    if to_date:
        query = query.filter(AuditLog.created_at <= datetime.combine(to_date, datetime.max.time()))
    
    total = query.count()
    
    logs = query.order_by(AuditLog.created_at.desc()) \
        .offset((page - 1) * per_page) \
        .limit(per_page) \
        .all()
    
    return AuditLogListResponse(
        total=total,
        page=page,
        per_page=per_page,
        logs=logs,
    )


@router.get("/pet/{pet_id}", response_model=AuditLogListResponse)
async def get_pet_activity(
    pet_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Lista atividades relacionadas a um pet específico.
    
    Apenas o dono do pet pode ver.
    """
    from app.models.pet import Pet
    
    pet = db.query(Pet).filter(Pet.id == pet_id, Pet.owner_id == current_user.id).first()
    if not pet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet não encontrado",
        )
    
    query = db.query(AuditLog).filter(
        AuditLog.resource_type == "pet",
        AuditLog.resource_id == pet_id,
    )
    
    total = query.count()
    
    logs = query.order_by(AuditLog.created_at.desc()) \
        .offset((page - 1) * per_page) \
        .limit(per_page) \
        .all()
    
    return AuditLogListResponse(
        total=total,
        page=page,
        per_page=per_page,
        logs=logs,
    )

