from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import (
    UserCreate,
    UserUpdate,
    UserUpdatePassword,
    UserLogin,
    UserResponse,
    Token,
    TokenRefresh,
    TokenResponse,
)
from app.core.security import (
    get_password_hash,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_current_user,
)
from app.core.config import settings
from app.services.audit_service import AuditService

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, request: Request, db: Session = Depends(get_db)):
    """Registra um novo usuário"""
    # Verifica se email já existe
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já cadastrado",
        )
    
    # Cria novo usuário
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        email=user_data.email,
        password_hash=hashed_password,
        full_name=user_data.full_name,
        phone=user_data.phone,
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Log de auditoria
    AuditService.log(
        db=db,
        action=AuditService.Actions.REGISTER,
        user_id=new_user.id,
        details={"email": new_user.email},
        request=request,
    )
    
    return new_user


@router.post("/login")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Login do usuário (compatível com Swagger OAuth2).
    
    - **username**: Email do usuário
    - **password**: Senha do usuário
    
    Retorna access_token e refresh_token.
    """
    user = db.query(User).filter(User.email == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.password_hash):
        AuditService.log(
            db=db,
            action=AuditService.Actions.LOGIN_FAILED,
            details={"email": form_data.username},
            request=request,
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou senha incorretos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuário inativo",
        )
    
    access_token = create_access_token(data={"sub": str(user.id)})
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    AuditService.log(
        db=db,
        action=AuditService.Actions.LOGIN,
        user_id=user.id,
        request=request,
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
    }


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(token_data: TokenRefresh, request: Request, db: Session = Depends(get_db)):
    """
    Renova o access_token usando o refresh_token.
    
    Use este endpoint quando o access_token expirar.
    O refresh_token é válido por 7 dias.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Refresh token inválido ou expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    # Decodifica e valida refresh token
    payload = decode_token(token_data.refresh_token, expected_type="refresh")
    if payload is None:
        raise credentials_exception
    
    user_id = payload.get("sub")
    if user_id is None:
        raise credentials_exception
    
    # Verifica se usuário existe e está ativo
    user = db.query(User).filter(User.id == user_id).first()
    if user is None or not user.is_active:
        raise credentials_exception
    
    # Criar novos tokens
    new_access_token = create_access_token(data={"sub": str(user.id)})
    new_refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    # Log de auditoria
    AuditService.log(
        db=db,
        action=AuditService.Actions.TOKEN_REFRESH,
        user_id=user.id,
        request=request,
    )
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "expires_in": settings.JWT_ACCESS_TOKEN_EXPIRES_MINUTES * 60,
    }


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Retorna informações do usuário atual"""
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_current_user(
    user_data: UserUpdate,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza informações do usuário atual"""
    update_data = user_data.model_dump(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    db.commit()
    db.refresh(current_user)
    
    # Log de auditoria
    AuditService.log(
        db=db,
        action=AuditService.Actions.USER_UPDATE,
        user_id=current_user.id,
        details={"updated_fields": list(update_data.keys())},
        request=request,
    )
    
    return current_user


@router.post("/me/password", status_code=status.HTTP_200_OK)
async def update_password(
    password_data: UserUpdatePassword,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Atualiza senha do usuário atual"""
    # Verifica senha atual
    if not verify_password(password_data.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Senha atual incorreta",
        )
    
    # Atualiza senha
    current_user.password_hash = get_password_hash(password_data.new_password)
    db.commit()
    
    # Log de auditoria
    AuditService.log(
        db=db,
        action=AuditService.Actions.PASSWORD_CHANGE,
        user_id=current_user.id,
        request=request,
    )
    
    return {"message": "Senha atualizada com sucesso"}

