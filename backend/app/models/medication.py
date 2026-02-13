from sqlalchemy import Column, Integer, String, DateTime, Date, ForeignKey, Text, Boolean, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class Medication(Base):
    """Medicamentos do pet com lembretes"""
    __tablename__ = "medications"
    
    id = Column(Integer, primary_key=True, index=True)
    pet_id = Column(Integer, ForeignKey("pets.id", ondelete="CASCADE"), nullable=False)
    
    # Dados do medicamento
    name = Column(String, nullable=False)  # Nome do medicamento
    dosage = Column(String, nullable=True)  # Ex: "1 comprimido", "5ml"
    frequency = Column(String, nullable=True)  # Ex: "2x ao dia", "a cada 8h"
    instructions = Column(Text, nullable=True)  # Instruções de uso
    
    # Período de tratamento
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)  # Null = uso contínuo
    
    # Lembrete
    reminder_enabled = Column(Boolean, default=True)
    reminder_times = Column(String, nullable=True)  # Ex: "08:00,12:00,20:00"
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Observações
    notes = Column(Text, nullable=True)
    prescribed_by = Column(String, nullable=True)  # Nome do veterinário que prescreveu
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    pet = relationship("Pet", back_populates="medications")


class MedicationLog(Base):
    """Registro de administração de medicamento"""
    __tablename__ = "medication_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    medication_id = Column(Integer, ForeignKey("medications.id", ondelete="CASCADE"), nullable=False)
    
    administered_at = Column(DateTime, nullable=False)
    administered_by = Column(String, nullable=True)  # Quem deu o medicamento
    notes = Column(Text, nullable=True)
    skipped = Column(Boolean, default=False)  # Se foi pulado
    skip_reason = Column(String, nullable=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    medication = relationship("Medication")
