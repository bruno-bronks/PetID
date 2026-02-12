from datetime import date, datetime, timedelta
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.vaccine_reminder import VaccineReminder
from app.models.pet import Pet


class VaccineService:
    """Serviço para gerenciamento de lembretes de vacinas"""
    
    # Vacinas comuns e seus intervalos padrão (em meses)
    COMMON_VACCINES = {
        "dog": {
            "V8/V10 (Polivalente)": 12,
            "Antirrábica": 12,
            "Gripe Canina": 12,
            "Giárdia": 12,
            "Leishmaniose": 12,
        },
        "cat": {
            "V3/V4/V5 (Polivalente)": 12,
            "Antirrábica": 12,
            "Leucemia Felina (FeLV)": 12,
        }
    }
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_reminder(
        self,
        pet_id: int,
        vaccine_name: str,
        scheduled_date: date,
        owner_id: int,
        notify_days_before: int = 7,
        notes: str = None
    ) -> Tuple[Optional[VaccineReminder], str]:
        """Cria um lembrete de vacina"""
        
        # Verifica se o pet pertence ao usuário
        pet = self.db.query(Pet).filter(
            Pet.id == pet_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not pet:
            return None, "Pet não encontrado"
        
        reminder = VaccineReminder(
            pet_id=pet_id,
            vaccine_name=vaccine_name,
            scheduled_date=scheduled_date,
            notify_days_before=notify_days_before,
            notes=notes
        )
        
        self.db.add(reminder)
        self.db.commit()
        self.db.refresh(reminder)
        
        return reminder, "Lembrete criado com sucesso"
    
    def list_reminders(
        self,
        owner_id: int,
        pet_id: int = None,
        include_completed: bool = False
    ) -> List[VaccineReminder]:
        """Lista lembretes de vacinas"""
        
        query = self.db.query(VaccineReminder).join(Pet).filter(
            Pet.owner_id == owner_id
        )
        
        if pet_id:
            query = query.filter(VaccineReminder.pet_id == pet_id)
        
        if not include_completed:
            query = query.filter(VaccineReminder.is_completed == False)
        
        reminders = query.order_by(VaccineReminder.scheduled_date).all()
        
        # Adiciona campos calculados
        today = date.today()
        for reminder in reminders:
            days_diff = (reminder.scheduled_date - today).days
            reminder.days_until = days_diff
            reminder.is_overdue = days_diff < 0 and not reminder.is_completed
        
        return reminders
    
    def get_upcoming_vaccines(
        self,
        owner_id: int,
        days_ahead: int = 30
    ) -> dict:
        """Retorna vacinas próximas e atrasadas"""
        
        today = date.today()
        future_date = today + timedelta(days=days_ahead)
        
        # Busca todas as vacinas pendentes
        all_reminders = self.db.query(VaccineReminder).join(Pet).filter(
            Pet.owner_id == owner_id,
            VaccineReminder.is_completed == False
        ).order_by(VaccineReminder.scheduled_date).all()
        
        upcoming = []
        overdue = []
        
        for reminder in all_reminders:
            days_diff = (reminder.scheduled_date - today).days
            reminder.days_until = days_diff
            reminder.is_overdue = days_diff < 0
            
            if days_diff < 0:
                overdue.append(reminder)
            elif days_diff <= days_ahead:
                upcoming.append(reminder)
        
        return {
            "upcoming": upcoming,
            "overdue": overdue,
            "total_pending": len(upcoming) + len(overdue)
        }
    
    def complete_reminder(
        self,
        reminder_id: int,
        owner_id: int,
        completed_date: date,
        record_id: int = None
    ) -> Tuple[Optional[VaccineReminder], str]:
        """Marca uma vacina como aplicada"""
        
        reminder = self.db.query(VaccineReminder).join(Pet).filter(
            VaccineReminder.id == reminder_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not reminder:
            return None, "Lembrete não encontrado"
        
        reminder.is_completed = True
        reminder.completed_date = completed_date
        reminder.record_id = record_id
        
        self.db.commit()
        self.db.refresh(reminder)
        
        return reminder, "Vacina marcada como aplicada"
    
    def update_reminder(
        self,
        reminder_id: int,
        owner_id: int,
        **kwargs
    ) -> Tuple[Optional[VaccineReminder], str]:
        """Atualiza um lembrete"""
        
        reminder = self.db.query(VaccineReminder).join(Pet).filter(
            VaccineReminder.id == reminder_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not reminder:
            return None, "Lembrete não encontrado"
        
        for key, value in kwargs.items():
            if value is not None and hasattr(reminder, key):
                setattr(reminder, key, value)
        
        self.db.commit()
        self.db.refresh(reminder)
        
        return reminder, "Lembrete atualizado"
    
    def delete_reminder(
        self,
        reminder_id: int,
        owner_id: int
    ) -> bool:
        """Remove um lembrete"""
        
        reminder = self.db.query(VaccineReminder).join(Pet).filter(
            VaccineReminder.id == reminder_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not reminder:
            return False
        
        self.db.delete(reminder)
        self.db.commit()
        return True
    
    def suggest_vaccines(self, pet_id: int, owner_id: int) -> List[dict]:
        """Sugere vacinas com base na espécie do pet"""
        
        pet = self.db.query(Pet).filter(
            Pet.id == pet_id,
            Pet.owner_id == owner_id
        ).first()
        
        if not pet:
            return []
        
        vaccines = self.COMMON_VACCINES.get(pet.species, {})
        
        # Verifica quais já estão agendadas
        existing = self.db.query(VaccineReminder.vaccine_name).filter(
            VaccineReminder.pet_id == pet_id,
            VaccineReminder.is_completed == False
        ).all()
        existing_names = {r.vaccine_name for r in existing}
        
        suggestions = []
        for name, interval_months in vaccines.items():
            suggestions.append({
                "vaccine_name": name,
                "interval_months": interval_months,
                "already_scheduled": name in existing_names
            })
        
        return suggestions
    
    def get_reminders_to_notify(self) -> List[VaccineReminder]:
        """
        Retorna lembretes que precisam ser notificados.
        Usado por um job/cron para enviar notificações.
        """
        today = date.today()
        
        reminders = self.db.query(VaccineReminder).filter(
            VaccineReminder.is_completed == False,
            VaccineReminder.scheduled_date <= today + timedelta(days=30)
        ).all()
        
        to_notify = []
        for reminder in reminders:
            days_until = (reminder.scheduled_date - today).days
            
            # Notifica se está dentro da janela de notificação
            if days_until <= reminder.notify_days_before:
                # Verifica se já foi notificado hoje
                if reminder.last_notified_at:
                    if reminder.last_notified_at.date() == today:
                        continue
                
                to_notify.append(reminder)
        
        return to_notify
    
    def mark_as_notified(self, reminder_ids: List[int]):
        """Marca lembretes como notificados"""
        self.db.query(VaccineReminder).filter(
            VaccineReminder.id.in_(reminder_ids)
        ).update(
            {"last_notified_at": datetime.utcnow()},
            synchronize_session=False
        )
        self.db.commit()

