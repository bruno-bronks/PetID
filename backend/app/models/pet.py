from sqlalchemy import Column, Integer, String, DateTime, Date, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base


class Pet(Base):
    __tablename__ = "pets"
    
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    species = Column(String, nullable=False)  # 'dog' ou 'cat'
    breed = Column(String, nullable=True)
    sex = Column(String, nullable=True)  # 'male', 'female', 'unknown'
    birth_date = Column(Date, nullable=True)
    weight = Column(String, nullable=True)
    is_castrated = Column(Boolean, default=False)
    microchip = Column(String, nullable=True, unique=True)
    photo_url = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    owner = relationship("User", back_populates="pets")
    records = relationship("MedicalRecord", back_populates="pet", cascade="all, delete-orphan", order_by="desc(MedicalRecord.event_date)")
    permissions = relationship("Permission", back_populates="pet", cascade="all, delete-orphan")
    snout_biometry = relationship("SnoutBiometry", back_populates="pet", uselist=False, cascade="all, delete-orphan")
    vaccine_reminders = relationship("VaccineReminder", back_populates="pet", cascade="all, delete-orphan")
    veterinarians = relationship("Veterinarian", back_populates="pet", cascade="all, delete-orphan")
    medications = relationship("Medication", back_populates="pet", cascade="all, delete-orphan")
    documents = relationship("PetDocument", back_populates="pet", cascade="all, delete-orphan")

