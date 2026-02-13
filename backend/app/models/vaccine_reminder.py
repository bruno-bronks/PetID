from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class VaccineReminder(Base):
    """Lembretes de vacinação para pets"""
    __tablename__ = "vaccine_reminders"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False)
    
    # Informações da vacina
    vaccine_name = Column(String, nullable=False)
    scheduled_date = Column(Date, nullable=False)
    
    # Status
    is_completed = Column(Boolean, default=False)
    completed_date = Column(Date, nullable=True)
    record_id = Column(Integer, ForeignKey("medical_records.id"), nullable=True)  # Link para o prontuário quando aplicada
    
    # Notificações
    notify_days_before = Column(Integer, default=7)  # Dias antes para notificar
    last_notified_at = Column(DateTime, nullable=True)
    
    # Observações
    notes = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    pet = relationship("Pet", back_populates="vaccine_reminders")
    record = relationship("MedicalRecord")

