from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Boolean, Text, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class LostPetReport(Base):
    """Reportes de pets perdidos/encontrados"""
    __tablename__ = "lost_pet_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id", ondelete="CASCADE"), nullable=True)  # Nullable para pets encontrados sem cadastro
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Tipo: 'lost' (perdido pelo dono) ou 'found' (encontrado por alguém)
    report_type = Column(String, nullable=False)  # 'lost' ou 'found'
    
    # Status
    status = Column(String, default='active')  # 'active', 'resolved', 'expired'
    
    # Localização
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address = Column(String, nullable=True)
    city = Column(String, nullable=True)
    
    # Detalhes
    description = Column(Text, nullable=True)
    contact_phone = Column(String, nullable=True)
    contact_visible = Column(Boolean, default=True)  # Mostrar telefone publicamente
    
    # Para pets encontrados (sem cadastro)
    found_species = Column(String, nullable=True)  # 'dog' ou 'cat'
    found_breed = Column(String, nullable=True)
    found_color = Column(String, nullable=True)
    found_photo_url = Column(String, nullable=True)
    
    # Data do evento
    event_date = Column(Date, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)
    
    # Relationships
    pet = relationship("Pet", backref="lost_reports")
    reporter = relationship("User", backref="lost_pet_reports")
