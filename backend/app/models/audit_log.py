from sqlalchemy import Column, Integer, String, DateTime, Text, JSON
from datetime import datetime
from app.db.session import Base


class AuditLog(Base):
    """
    Tabela de auditoria para registrar ações importantes no sistema.
    
    Registra:
    - Logins/logouts
    - Criação/edição/exclusão de pets
    - Acesso a prontuários
    - Uploads/downloads de anexos
    - Compartilhamentos de acesso
    """
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True, index=True)  # Pode ser null para ações anônimas
    action = Column(String(100), nullable=False, index=True)  # Ex: 'login', 'pet.create', 'record.view'
    resource_type = Column(String(50), nullable=True)  # Ex: 'pet', 'record', 'attachment'
    resource_id = Column(Integer, nullable=True)  # ID do recurso afetado
    details = Column(JSON, nullable=True)  # Detalhes adicionais em JSON
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

