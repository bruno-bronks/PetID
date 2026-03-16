import 'api_service.dart';

class Veterinarian {
  final int id;
  final int petId;
  final String name;
  final String? clinicName;
  final String? phone;
  final String? email;
  final String? address;
  final String? specialty;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Veterinarian({
    required this.id,
    required this.petId,
    required this.name,
    this.clinicName,
    this.phone,
    this.email,
    this.address,
    this.specialty,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Veterinarian.fromJson(Map<String, dynamic> json) {
    return Veterinarian(
      id: json['id'],
      petId: json['pet_id'],
      name: json['name'],
      clinicName: json['clinic_name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      specialty: json['specialty'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class VeterinarianService {
  final _api = ApiService();

  Future<List<Veterinarian>> listVeterinarians(int petId) async {
    final response = await _api.get('/pets/$petId/veterinarians');
    return (response as List).map((v) => Veterinarian.fromJson(v)).toList();
  }

  Future<Veterinarian> createVeterinarian({
    required int petId,
    required String name,
    String? clinicName,
    String? phone,
    String? email,
    String? address,
    String? specialty,
    String? notes,
  }) async {
    final response = await _api.post('/pets/$petId/veterinarians', {
      'pet_id': petId,
      'name': name,
      if (clinicName != null) 'clinic_name': clinicName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (specialty != null) 'specialty': specialty,
      if (notes != null) 'notes': notes,
    });
    return Veterinarian.fromJson(response);
  }

  Future<Veterinarian> updateVeterinarian({
    required int petId,
    required int vetId,
    String? name,
    String? clinicName,
    String? phone,
    String? email,
    String? address,
    String? specialty,
    String? notes,
  }) async {
    final response = await _api.patch('/pets/$petId/veterinarians/$vetId', {
      if (name != null) 'name': name,
      if (clinicName != null) 'clinic_name': clinicName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (specialty != null) 'specialty': specialty,
      if (notes != null) 'notes': notes,
    });
    return Veterinarian.fromJson(response);
  }

  Future<void> deleteVeterinarian(int petId, int vetId) async {
    await _api.delete('/pets/$petId/veterinarians/$vetId');
  }
}
