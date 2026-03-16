import 'api_service.dart';
import 'pet_service.dart';
import 'notification_service.dart';

class VaccineReminder {
  final int id;
  final int petId;
  final String vaccineName;
  final DateTime scheduledDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final int? recordId;
  final int notifyDaysBefore;
  final String? notes;
  final int? daysUntil;
  final bool isOverdue;

  VaccineReminder({
    required this.id,
    required this.petId,
    required this.vaccineName,
    required this.scheduledDate,
    required this.isCompleted,
    this.completedDate,
    this.recordId,
    required this.notifyDaysBefore,
    this.notes,
    this.daysUntil,
    this.isOverdue = false,
  });

  factory VaccineReminder.fromJson(Map<String, dynamic> json) {
    return VaccineReminder(
      id: json['id'],
      petId: json['pet_id'],
      vaccineName: json['vaccine_name'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      isCompleted: json['is_completed'] ?? false,
      completedDate: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date']) 
          : null,
      recordId: json['record_id'],
      notifyDaysBefore: json['notify_days_before'] ?? 7,
      notes: json['notes'],
      daysUntil: json['days_until'],
      isOverdue: json['is_overdue'] ?? false,
    );
  }

  String get statusText {
    if (isCompleted) return 'Aplicada';
    if (isOverdue) return 'Atrasada';
    if (daysUntil != null) {
      if (daysUntil == 0) return 'Hoje';
      if (daysUntil == 1) return 'Amanhã';
      if (daysUntil! <= 7) return 'Em $daysUntil dias';
      return 'Agendada';
    }
    return 'Pendente';
  }
}

class VaccineSuggestion {
  final String vaccineName;
  final int intervalMonths;
  final bool alreadyScheduled;

  VaccineSuggestion({
    required this.vaccineName,
    required this.intervalMonths,
    required this.alreadyScheduled,
  });

  factory VaccineSuggestion.fromJson(Map<String, dynamic> json) {
    return VaccineSuggestion(
      vaccineName: json['vaccine_name'],
      intervalMonths: json['interval_months'],
      alreadyScheduled: json['already_scheduled'] ?? false,
    );
  }
}

class UpcomingVaccines {
  final List<VaccineReminder> upcoming;
  final List<VaccineReminder> overdue;
  final int totalPending;

  UpcomingVaccines({
    required this.upcoming,
    required this.overdue,
    required this.totalPending,
  });

  factory UpcomingVaccines.fromJson(Map<String, dynamic> json) {
    return UpcomingVaccines(
      upcoming: (json['upcoming'] as List)
          .map((r) => VaccineReminder.fromJson(r))
          .toList(),
      overdue: (json['overdue'] as List)
          .map((r) => VaccineReminder.fromJson(r))
          .toList(),
      totalPending: json['total_pending'],
    );
  }

  bool get hasOverdue => overdue.isNotEmpty;
  bool get hasUpcoming => upcoming.isNotEmpty;
}

class VaccineService {
  final ApiService _api = ApiService();

  /// Cria um lembrete de vacina
  Future<VaccineReminder> createReminder({
    required int petId,
    required String vaccineName,
    required DateTime scheduledDate,
    int notifyDaysBefore = 7,
    String? notes,
  }) async {
    final response = await _api.post('/vaccines', {
      'pet_id': petId,
      'vaccine_name': vaccineName,
      'scheduled_date': scheduledDate.toIso8601String().split('T').first,
      'notify_days_before': notifyDaysBefore,
      if (notes != null) 'notes': notes,
    });
    
    final reminder = VaccineReminder.fromJson(response);
    
    // Add Notification
    try {
      final petService = PetService();
      final pet = await petService.getPet(petId);
      final petName = pet.name;
      
      await NotificationService().scheduleVaccineReminder(
        reminderId: reminder.id,
        petName: petName,
        vaccineName: vaccineName,
        scheduledDate: scheduledDate,
        daysBefore: notifyDaysBefore,
      );
    } catch (e) {
      print('Erro ao agendar notificação de vacina: $e');
    }
    
    return reminder;
  }

  /// Lista lembretes de vacinas
  Future<List<VaccineReminder>> listReminders({
    int? petId,
    bool includeCompleted = false,
  }) async {
    var endpoint = '/vaccines';
    final params = <String>[];
    
    if (petId != null) params.add('pet_id=$petId');
    if (includeCompleted) params.add('include_completed=true');
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await _api.get(endpoint);
    return (response as List)
        .map((r) => VaccineReminder.fromJson(r))
        .toList();
  }

  /// Obtém vacinas próximas e atrasadas
  Future<UpcomingVaccines> getUpcomingVaccines({int daysAhead = 30}) async {
    final response = await _api.get('/vaccines/upcoming?days_ahead=$daysAhead');
    return UpcomingVaccines.fromJson(response);
  }

  /// Obtém sugestões de vacinas para um pet
  Future<List<VaccineSuggestion>> getSuggestions(int petId) async {
    final response = await _api.get('/vaccines/suggestions/$petId');
    return (response['suggestions'] as List)
        .map((s) => VaccineSuggestion.fromJson(s))
        .toList();
  }

  /// Obtém detalhes de um lembrete
  Future<VaccineReminder> getReminder(int reminderId) async {
    final response = await _api.get('/vaccines/$reminderId');
    return VaccineReminder.fromJson(response);
  }

  /// Atualiza um lembrete
  Future<VaccineReminder> updateReminder(
    int reminderId, {
    String? vaccineName,
    DateTime? scheduledDate,
    int? notifyDaysBefore,
    String? notes,
  }) async {
    final data = <String, dynamic>{};
    if (vaccineName != null) data['vaccine_name'] = vaccineName;
    if (scheduledDate != null) {
      data['scheduled_date'] = scheduledDate.toIso8601String().split('T').first;
    }
    if (notifyDaysBefore != null) data['notify_days_before'] = notifyDaysBefore;
    if (notes != null) data['notes'] = notes;
    
    final response = await _api.patch('/vaccines/$reminderId', data);
    final reminder = VaccineReminder.fromJson(response);
    
    // Update Notification
    try {
      if (reminder.scheduledDate.isAfter(DateTime.now())) {
        final petService = PetService();
        final pet = await petService.getPet(reminder.petId);
        final petName = pet.name;
        
        await NotificationService().cancelReminder(reminderId);
        await NotificationService().scheduleVaccineReminder(
          reminderId: reminder.id,
          petName: petName,
          vaccineName: reminder.vaccineName,
          scheduledDate: reminder.scheduledDate,
          daysBefore: reminder.notifyDaysBefore,
        );
      }
    } catch (e) {
      print('Erro ao atualizar notificação de vacina: $e');
    }
    
    return reminder;
  }

  /// Marca vacina como aplicada
  Future<VaccineReminder> completeReminder(
    int reminderId, {
    required DateTime completedDate,
    int? recordId,
  }) async {
    final response = await _api.post('/vaccines/$reminderId/complete', {
      'completed_date': completedDate.toIso8601String().split('T').first,
      if (recordId != null) 'record_id': recordId,
    });
    
    // Cancel any pending notifications
    await NotificationService().cancelReminder(reminderId);
    
    return VaccineReminder.fromJson(response);
  }

  /// Remove um lembrete
  Future<void> deleteReminder(int reminderId) async {
    await _api.delete('/vaccines/$reminderId');
    await NotificationService().cancelReminder(reminderId);
  }
}

