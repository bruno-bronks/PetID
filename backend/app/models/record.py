from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class MedicalRecord(Base):
    __tablename__ = "medical_records"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id"), nullable=False)
    type = Column(String, nullable=False)  # 'vaccine', 'visit', 'diagnosis', 'medication', 'exam', 'procedure', 'allergy'
    title = Column(String, nullable=False)
    notes = Column(Text, nullable=True)
    event_date = Column(Date, nullable=False)
    extra_data = Column(JSON, nullable=True)  # Campos extras flexíveis (lote vacina, dose, peso, etc.)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    pet = relationship("Pet", back_populates="records")
    attachments = relationship("Attachment", back_populates="record", cascade="all, delete-orphan")

