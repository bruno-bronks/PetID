import 'api_service.dart';

class LostPetReport {
  final int id;
  final int? petId;
  final int reporterId;
  final String reportType;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? description;
  final String? contactPhone;
  final bool contactVisible;
  final DateTime eventDate;
  final DateTime createdAt;
  final String? petName;
  final String? petSpecies;
  final String? petBreed;
  final String? petPhotoUrl;
  final String? foundSpecies;
  final String? foundBreed;
  final String? foundColor;
  final double? distanceKm;

  LostPetReport({
    required this.id,
    this.petId,
    required this.reporterId,
    required this.reportType,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.description,
    this.contactPhone,
    required this.contactVisible,
    required this.eventDate,
    required this.createdAt,
    this.petName,
    this.petSpecies,
    this.petBreed,
    this.petPhotoUrl,
    this.foundSpecies,
    this.foundBreed,
    this.foundColor,
    this.distanceKm,
  });

  factory LostPetReport.fromJson(Map<String, dynamic> json) {
    return LostPetReport(
      id: json['id'],
      petId: json['pet_id'],
      reporterId: json['reporter_id'],
      reportType: json['report_type'],
      status: json['status'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      city: json['city'],
      description: json['description'],
      contactPhone: json['contact_phone'],
      contactVisible: json['contact_visible'] ?? true,
      eventDate: DateTime.parse(json['event_date']),
      createdAt: DateTime.parse(json['created_at']),
      petName: json['pet_name'],
      petSpecies: json['pet_species'],
      petBreed: json['pet_breed'],
      petPhotoUrl: json['pet_photo_url'],
      foundSpecies: json['found_species'],
      foundBreed: json['found_breed'],
      foundColor: json['found_color'],
      distanceKm: json['distance_km']?.toDouble(),
    );
  }

  String get displayName => petName ?? 'Pet ${foundSpecies == 'dog' ? 'Cachorro' : 'Gato'}';
  String get speciesLabel => (petSpecies ?? foundSpecies) == 'dog' ? 'Cachorro' : 'Gato';
  bool get isLost => reportType == 'lost';
  bool get isFound => reportType == 'found';
  
  String get distanceText {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) return '${(distanceKm! * 1000).round()}m';
    return '${distanceKm!.toStringAsFixed(1)}km';
  }
}

class PetPublicProfile {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final String? photoUrl;
  final bool isLost;
  final String? ownerName;
  final String? ownerPhone;
  final bool hasBiometry;

  PetPublicProfile({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.photoUrl,
    required this.isLost,
    this.ownerName,
    this.ownerPhone,
    required this.hasBiometry,
  });

  factory PetPublicProfile.fromJson(Map<String, dynamic> json) {
    return PetPublicProfile(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      sex: json['sex'],
      photoUrl: json['photo_url'],
      isLost: json['is_lost'] ?? false,
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      hasBiometry: json['has_biometry'] ?? false,
    );
  }

  String get speciesLabel => species == 'dog' ? 'Cachorro' : 'Gato';
  String get sexLabel {
    switch (sex) {
      case 'male': return 'Macho';
      case 'female': return 'Fêmea';
      default: return 'Não informado';
    }
  }
}

class LostPetService {
  final ApiService _api = ApiService();

  /// Obtém perfil público de um pet (para QR Code)
  Future<PetPublicProfile> getPublicProfile(int petId) async {
    final response = await _api.get('/public/pet/$petId');
    return PetPublicProfile.fromJson(response);
  }

  /// Reportar pet perdido
  Future<LostPetReport> reportLost({
    required int petId,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? description,
    String? contactPhone,
    bool contactVisible = true,
    required DateTime eventDate,
  }) async {
    final response = await _api.post('/public/lost-pets/report', {
      'pet_id': petId,
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (description != null) 'description': description,
      if (contactPhone != null) 'contact_phone': contactPhone,
      'contact_visible': contactVisible,
      'event_date': eventDate.toIso8601String().split('T').first,
    });
    return LostPetReport.fromJson(response);
  }

  /// Reportar pet encontrado
  Future<LostPetReport> reportFound({
    required double latitude,
    required double longitude,
    required String species,
    String? breed,
    String? color,
    String? address,
    String? city,
    String? description,
    String? contactPhone,
    bool contactVisible = true,
    required DateTime eventDate,
    int? petId, // Se identificou pelo focinho
  }) async {
    final response = await _api.post('/public/lost-pets/found', {
      'latitude': latitude,
      'longitude': longitude,
      'found_species': species,
      if (breed != null) 'found_breed': breed,
      if (color != null) 'found_color': color,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (description != null) 'description': description,
      if (contactPhone != null) 'contact_phone': contactPhone,
      'contact_visible': contactVisible,
      'event_date': eventDate.toIso8601String().split('T').first,
      if (petId != null) 'pet_id': petId,
    });
    return LostPetReport.fromJson(response);
  }

  /// Busca pets perdidos/encontrados próximos
  Future<List<LostPetReport>> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? reportType, // 'lost', 'found', ou null para ambos
  }) async {
    var endpoint = '/public/lost-pets/nearby?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm';
    if (reportType != null) {
      endpoint += '&report_type=$reportType';
    }
    
    final response = await _api.get(endpoint);
    return (response as List).map((r) => LostPetReport.fromJson(r)).toList();
  }

  /// Lista meus reportes
  Future<List<LostPetReport>> getMyReports() async {
    final response = await _api.get('/public/lost-pets/my-reports');
    return (response as List).map((r) => LostPetReport.fromJson(r)).toList();
  }

  /// Marca reporte como resolvido
  Future<void> resolveReport(int reportId) async {
    await _api.patch('/public/lost-pets/$reportId/resolve', {});
  }

  /// Remove reporte
  Future<void> deleteReport(int reportId) async {
    await _api.delete('/public/lost-pets/$reportId');
  }

  /// Gera URL do perfil público para QR Code
  String getPublicProfileUrl(int petId) {
    // URL pública que pode ser acessada por qualquer pessoa
    return 'http://148.230.79.134:8080/pet/$petId';
  }
}
