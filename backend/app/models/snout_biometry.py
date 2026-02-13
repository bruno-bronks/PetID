from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Index
from sqlalchemy.orm import relationship
from datetime import datetime
from pgvector.sqlalchemy import Vector
from app.db.session import Base


class SnoutBiometry(Base):
    """Armazena o embedding biométrico do focinho do pet"""
    __tablename__ = "snout_biometries"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False, unique=True)
    
    # Embedding do focinho (768 dimensões - MegaDescriptor Swin Transformer)
    embedding = Column(Vector(768), nullable=False)
    
    # Metadados
    quality_score = Column(Integer, nullable=True)  # 0-100, qualidade da imagem capturada
    is_active = Column(Boolean, default=True)  # Permite desativar sem deletar
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationship
    pet = relationship("Pet", back_populates="snout_biometry")
    
    # Índice para busca vetorial eficiente (usando IVFFlat para grandes volumes)
    __table_args__ = (
        Index(
            'ix_snout_biometries_embedding',
            embedding,
            postgresql_using='ivfflat',
            postgresql_with={'lists': 100},
            postgresql_ops={'embedding': 'vector_cosine_ops'}
        ),
    )

