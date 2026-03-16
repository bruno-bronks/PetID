import 'api_service.dart';

/// Tipos de registro médico
class RecordType {
  static const String vaccine = 'vaccine';
  static const String visit = 'visit';
  static const String diagnosis = 'diagnosis';
  static const String medication = 'medication';
  static const String exam = 'exam';
  static const String procedure = 'procedure';
  static const String allergy = 'allergy';
  
  static List<String> get all => [
    vaccine, visit, diagnosis, medication, exam, procedure, allergy,
  ];
  
  static String label(String type) {
    switch (type) {
      case vaccine: return 'Vacina';
      case visit: return 'Consulta';
      case diagnosis: return 'Diagnóstico';
      case medication: return 'Medicação';
      case exam: return 'Exame';
      case procedure: return 'Procedimento';
      case allergy: return 'Alergia';
      default: return type;
    }
  }
}

class RecordService {
  final ApiService _api = ApiService();
  
  /// Lista registros médicos de um pet
  Future<List<dynamic>> listRecords(
    int petId, {
    String? type,
    String? fromDate,
    String? toDate,
  }) async {
    var endpoint = '/pets/$petId/records';
    final params = <String>[];
    
    if (type != null) params.add('record_type=$type');
    if (fromDate != null) params.add('from_date=$fromDate');
    if (toDate != null) params.add('to_date=$toDate');
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    final response = await _api.get(endpoint);
    return response as List<dynamic>;
  }
  
  /// Obtém detalhes de um registro
  Future<Map<String, dynamic>> getRecord(int petId, int recordId) async {
    final response = await _api.get('/pets/$petId/records/$recordId');
    return response;
  }
  
  /// Cria um novo registro médico
  Future<Map<String, dynamic>> createRecord({
    required int petId,
    required String type,
    required String title,
    required String eventDate, // YYYY-MM-DD
    String? notes,
    Map<String, dynamic>? extraData,
  }) async {
    final data = {
      'pet_id': petId,
      'type': type,
      'title': title,
      'event_date': eventDate,
      if (notes != null) 'notes': notes,
      if (extraData != null) 'extra_data': extraData,
    };
    
    final response = await _api.post('/pets/$petId/records', data);
    return response;
  }
  
  /// Atualiza um registro
  Future<Map<String, dynamic>> updateRecord(
    int petId,
    int recordId,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.patch('/pets/$petId/records/$recordId', data);
    return response;
  }
  
  /// Deleta um registro
  Future<void> deleteRecord(int petId, int recordId) async {
    await _api.delete('/pets/$petId/records/$recordId');
  }
}

