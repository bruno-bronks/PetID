import 'api_service.dart';
import 'pet_service.dart';
import 'notification_service.dart';

class Medication {
  final int id;
  final int petId;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool reminderEnabled;
  final String? reminderTimes;
  final bool isActive;
  final String? notes;
  final String? prescribedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication({
    required this.id,
    required this.petId,
    required this.name,
    this.dosage,
    this.frequency,
    this.instructions,
    required this.startDate,
    this.endDate,
    required this.reminderEnabled,
    this.reminderTimes,
    required this.isActive,
    this.notes,
    this.prescribedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      petId: json['pet_id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      instructions: json['instructions'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      reminderEnabled: json['reminder_enabled'] ?? false,
      reminderTimes: json['reminder_times'],
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      prescribedBy: json['prescribed_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isContinuous => endDate == null;
  
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }
  
  List<String> get reminderTimesList {
    if (reminderTimes == null || reminderTimes!.isEmpty) return [];
    return reminderTimes!.split(',');
  }
}

class MedicationLog {
  final int id;
  final int medicationId;
  final DateTime administeredAt;
  final String? administeredBy;
  final String? notes;
  final bool skipped;
  final String? skipReason;
  final DateTime createdAt;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.administeredAt,
    this.administeredBy,
    this.notes,
    required this.skipped,
    this.skipReason,
    required this.createdAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      medicationId: json['medication_id'],
      administeredAt: DateTime.parse(json['administered_at']),
      administeredBy: json['administered_by'],
      notes: json['notes'],
      skipped: json['skipped'] ?? false,
      skipReason: json['skip_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class MedicationService {
  final _api = ApiService();

  Future<List<Medication>> listMedications(int petId, {bool activeOnly = false}) async {
    final response = await _api.get('/pets/$petId/medications?active_only=$activeOnly');
    return (response as List).map((m) => Medication.fromJson(m)).toList();
  }

  Future<Medication> createMedication({
    required int petId,
    required String name,
    required DateTime startDate,
    String? dosage,
    String? frequency,
    String? instructions,
    DateTime? endDate,
    bool reminderEnabled = true,
    String? reminderTimes,
    String? notes,
    String? prescribedBy,
  }) async {
    final response = await _api.post('/pets/$petId/medications', {
      'pet_id': petId,
      'name': name,
      'start_date': startDate.toIso8601String().split('T').first,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (instructions != null) 'instructions': instructions,
      if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
      'reminder_enabled': reminderEnabled,
      if (reminderTimes != null) 'reminder_times': reminderTimes,
      if (notes != null) 'notes': notes,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
    });
    final medication = Medication.fromJson(response);
    
    // Add Notification
    if (medication.reminderEnabled && medication.reminderTimesList.isNotEmpty) {
      try {
        final petService = PetService();
        final pet = await petService.getPet(petId);
        final petName = pet.name;
        
        for (int i = 0; i < medication.reminderTimesList.length; i++) {
          final time = medication.reminderTimesList[i].trim();
          if (time.isNotEmpty) {
            await NotificationService().scheduleMedicationReminder(
              medicationId: medication.id * 10 + i,
              petName: petName,
              medicationName: medication.name,
              time: time,
              daily: true,
            );
          }
        }
      } catch (e) {
        print('Erro ao agendar notificação de medicamento: $e');
      }
    }
    
    return medication;
  }

  Future<Medication> updateMedication({
    required int petId,
    required int medicationId,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    bool? reminderEnabled,
    String? reminderTimes,
    bool? isActive,
    String? notes,
    String? prescribedBy,
  }) async {
    final response = await _api.patch('/pets/$petId/medications/$medicationId', {
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (instructions != null) 'instructions': instructions,
      if (startDate != null) 'start_date': startDate.toIso8601String().split('T').first,
      if (endDate != null) 'end_date': endDate.toIso8601String().split('T').first,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderTimes != null) 'reminder_times': reminderTimes,
      if (isActive != null) 'is_active': isActive,
      if (notes != null) 'notes': notes,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
    });
    final medication = Medication.fromJson(response);
    
    // Update Notification
    try {
      for (int i = 0; i < 5; i++) {
        await NotificationService().cancelReminder(medicationId * 10 + i + 100000); 
      }
      
      if (medication.isActive && medication.reminderEnabled && medication.reminderTimesList.isNotEmpty) {
        final petService = PetService();
        final pet = await petService.getPet(petId);
        final petName = pet.name;
        
        for (int i = 0; i < medication.reminderTimesList.length; i++) {
          final time = medication.reminderTimesList[i].trim();
          if (time.isNotEmpty) {
            await NotificationService().scheduleMedicationReminder(
              medicationId: medication.id * 10 + i,
              petName: petName,
              medicationName: medication.name,
              time: time,
              daily: true,
            );
          }
        }
      }
    } catch (e) {
      print('Erro ao atualizar notificação de medicamento: $e');
    }
    
    return medication;
  }

  Future<void> deleteMedication(int petId, int medicationId) async {
    await _api.delete('/pets/$petId/medications/$medicationId');
    for (int i = 0; i < 5; i++) {
      await NotificationService().cancelReminder(medicationId * 10 + i + 100000);
    }
  }

  Future<MedicationLog> logMedication({
    required int petId,
    required int medicationId,
    required DateTime administeredAt,
    String? administeredBy,
    String? notes,
    bool skipped = false,
    String? skipReason,
  }) async {
    final response = await _api.post('/pets/$petId/medications/$medicationId/logs', {
      'administered_at': administeredAt.toIso8601String(),
      if (administeredBy != null) 'administered_by': administeredBy,
      if (notes != null) 'notes': notes,
      'skipped': skipped,
      if (skipReason != null) 'skip_reason': skipReason,
    });
    return MedicationLog.fromJson(response);
  }

  Future<List<MedicationLog>> getMedicationLogs(int petId, int medicationId) async {
    final response = await _api.get('/pets/$petId/medications/$medicationId/logs');
    return (response as List).map((l) => MedicationLog.fromJson(l)).toList();
  }
}
