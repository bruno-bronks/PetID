import 'dart:convert';
import 'dart:io';
import 'api_service.dart';

class PetSearchResult {
  final int petId;
  final String petName;
  final String species;
  final String? breed;
  final String? ownerName;
  final String? ownerPhone;
  final double similarity;
  final bool hasContactPermission;

  PetSearchResult({
    required this.petId,
    required this.petName,
    required this.species,
    this.breed,
    this.ownerName,
    this.ownerPhone,
    required this.similarity,
    this.hasContactPermission = true,
  });

  factory PetSearchResult.fromJson(Map<String, dynamic> json) {
    return PetSearchResult(
      petId: json['pet_id'],
      petName: json['pet_name'],
      species: json['species'],
      breed: json['breed'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      similarity: (json['similarity'] as num).toDouble(),
      hasContactPermission: json['has_contact_permission'] ?? true,
    );
  }

  String get speciesLabel => species == 'dog' ? 'Cachorro' : 'Gato';
  
  int get similarityPercent => (similarity * 100).round();
}

class BiometrySearchResponse {
  final bool found;
  final List<PetSearchResult> results;
  final String message;

  BiometrySearchResponse({
    required this.found,
    required this.results,
    required this.message,
  });

  factory BiometrySearchResponse.fromJson(Map<String, dynamic> json) {
    return BiometrySearchResponse(
      found: json['found'],
      results: (json['results'] as List)
          .map((r) => PetSearchResult.fromJson(r))
          .toList(),
      message: json['message'],
    );
  }
}

class BiometryService {
  final ApiService _api = ApiService();

  /// Converte arquivo de imagem para base64
  Future<String> _imageToBase64(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Registra biometria do focinho de um pet
  Future<Map<String, dynamic>> registerSnout({
    required int petId,
    required String imagePath,
  }) async {
    final imageBase64 = await _imageToBase64(imagePath);
    
    final response = await _api.post('/biometry/register', {
      'pet_id': petId,
      'image_base64': imageBase64,
    });
    
    return response;
  }

  /// Busca pet por focinho (público - não requer auth)
  Future<BiometrySearchResponse> searchBySnout({
    required String imagePath,
    double threshold = 0.85,
    int maxResults = 5,
  }) async {
    final imageBase64 = await _imageToBase64(imagePath);
    
    final response = await _api.post('/biometry/search', {
      'image_base64': imageBase64,
      'threshold': threshold,
      'max_results': maxResults,
    }, includeAuth: false);
    
    return BiometrySearchResponse.fromJson(response);
  }

  /// Obtém biometria de um pet
  Future<Map<String, dynamic>?> getBiometry(int petId) async {
    try {
      final response = await _api.get('/biometry/$petId');
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Remove biometria de um pet
  Future<void> deleteBiometry(int petId) async {
    await _api.delete('/biometry/$petId');
  }

  /// Verifica se um pet tem biometria cadastrada
  Future<bool> hasBiometry(int petId) async {
    final biometry = await getBiometry(petId);
    return biometry != null;
  }
}

