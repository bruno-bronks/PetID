from sqlalchemy.orm import Session
from fastapi import Request
from typing import Optional, Any, Dict
from app.models.audit_log import AuditLog


class AuditService:
    """Serviço para registrar logs de auditoria"""
    
    # Ações disponíveis
    class Actions:
        # Auth
        LOGIN = "auth.login"
        LOGIN_FAILED = "auth.login_failed"
        LOGOUT = "auth.logout"
        REGISTER = "auth.register"
        PASSWORD_CHANGE = "auth.password_change"
        TOKEN_REFRESH = "auth.token_refresh"
        
        # User
        USER_UPDATE = "user.update"
        
        # Pet
        PET_CREATE = "pet.create"
        PET_UPDATE = "pet.update"
        PET_DELETE = "pet.delete"
        PET_VIEW = "pet.view"
        
        # Medical Records
        RECORD_CREATE = "record.create"
        RECORD_UPDATE = "record.update"
        RECORD_DELETE = "record.delete"
        RECORD_VIEW = "record.view"
        
        # Attachments
        ATTACHMENT_UPLOAD = "attachment.upload"
        ATTACHMENT_DOWNLOAD = "attachment.download"
        ATTACHMENT_DELETE = "attachment.delete"
        
        # Permissions
        PERMISSION_GRANT = "permission.grant"
        PERMISSION_REVOKE = "permission.revoke"
    
    @staticmethod
    def log(
        db: Session,
        action: str,
        user_id: Optional[int] = None,
        resource_type: Optional[str] = None,
        resource_id: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None,
        request: Optional[Request] = None,
    ) -> AuditLog:
        """
        Registra uma ação de auditoria.
        
        Args:
            db: Sessão do banco de dados
            action: Tipo da ação (use AuditService.Actions)
            user_id: ID do usuário que executou a ação
            resource_type: Tipo do recurso (pet, record, attachment)
            resource_id: ID do recurso afetado
            details: Detalhes adicionais em formato dict
            request: Objeto Request do FastAPI para extrair IP e User-Agent
        """
        ip_address = None
        user_agent = None
        
        if request:
            # Tenta pegar IP real (considerando proxy)
            forwarded_for = request.headers.get("X-Forwarded-For")
            if forwarded_for:
                ip_address = forwarded_for.split(",")[0].strip()
            else:
                ip_address = request.client.host if request.client else None
            
            user_agent = request.headers.get("User-Agent", "")[:500]
        
        audit_log = AuditLog(
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        
        db.add(audit_log)
        db.commit()
        db.refresh(audit_log)
        
        return audit_log
    
    @staticmethod
    def log_async(
        db: Session,
        action: str,
        user_id: Optional[int] = None,
        resource_type: Optional[str] = None,
        resource_id: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
    ) -> None:
        """
        Versão que não faz commit (para usar em transações existentes).
        """
        audit_log = AuditLog(
            user_id=user_id,
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        
        db.add(audit_log)

