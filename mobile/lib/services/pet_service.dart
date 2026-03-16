import 'api_service.dart';
import '../models/pet.dart';

class PetService {
  final ApiService _api = ApiService();
  
  /// Lista todos os pets do usuário
  Future<List<Pet>> listPets() async {
    final response = await _api.get('/pets');
    final list = response as List<dynamic>;
    return list.map((json) => Pet.fromJson(json)).toList();
  }
  
  /// Obtém detalhes de um pet
  Future<Pet> getPet(int petId) async {
    final response = await _api.get('/pets/$petId');
    return Pet.fromJson(response);
  }
  
  /// Cria um novo pet
  Future<Map<String, dynamic>> createPet({
    required String name,
    required String species, // 'dog' ou 'cat'
    String? breed,
    String? sex, // 'male', 'female', 'unknown'
    String? birthDate, // YYYY-MM-DD
    String? weight,
    String? color,
    bool isCastrated = false,
    String? microchip,
    String? notes,
  }) async {
    final data = {
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (color != null) 'color': color,
      if (sex != null) 'sex': sex,
      if (birthDate != null) 'birth_date': birthDate,
      if (weight != null) 'weight': weight,
      'is_castrated': isCastrated,
      if (microchip != null) 'microchip': microchip,
      if (notes != null) 'notes': notes,
    };
    
    final response = await _api.post('/pets', data);
    return response;
  }
  
  /// Atualiza um pet
  Future<Map<String, dynamic>> updatePet(int petId, Map<String, dynamic> data) async {
    final response = await _api.patch('/pets/$petId', data);
    return response;
  }
  
  /// Faz upload da foto do pet
  Future<Map<String, dynamic>> uploadPhoto(int petId, String filePath) async {
    final response = await _api.uploadFile('/pets/$petId/photo', filePath, 'file');
    return response;
  }
  
  /// Deleta um pet
  Future<void> deletePet(int petId) async {
    await _api.delete('/pets/$petId');
  }
}

