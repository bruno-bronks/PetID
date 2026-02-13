from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class PetDocument(Base):
    """Documentos do pet (carteira de vacinação, atestados, etc)"""
    __tablename__ = "pet_documents"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False)
    
    # Dados do documento
    title = Column(String, nullable=False)  # Ex: "Carteira de Vacinação", "Atestado de Saúde"
    document_type = Column(String, nullable=False)  # Ex: "vaccination_card", "health_certificate", "exam", "other"
    description = Column(Text, nullable=True)
    
    # Arquivo
    file_url = Column(String, nullable=False)
    file_name = Column(String, nullable=False)
    file_type = Column(String, nullable=True)  # Ex: "application/pdf", "image/jpeg"
    file_size = Column(Integer, nullable=True)  # Em bytes
    
    # Datas relevantes
    document_date = Column(DateTime, nullable=True)  # Data do documento
    expiry_date = Column(DateTime, nullable=True)  # Data de validade (se aplicável)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    pet = relationship("Pet", back_populates="documents")
