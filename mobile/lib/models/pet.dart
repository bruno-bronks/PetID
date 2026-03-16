class Pet {
  final int id;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final String? birthDate;
  final String? weight;
  final String? color;
  final bool isCastrated;
  final String? microchip;
  final String? photoUrl;
  final String? notes;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.weight,
    this.color,
    this.isCastrated = false,
    this.microchip,
    this.photoUrl,
    this.notes,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      species: json['species'],
      breed: json['breed'],
      sex: json['sex'],
      birthDate: json['birth_date'],
      weight: json['weight']?.toString(),
      color: json['color'],
      isCastrated: json['is_castrated'] ?? false,
      microchip: json['microchip'],
      photoUrl: json['photo_url'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'sex': sex,
      'birth_date': birthDate,
      'weight': weight,
      'color': color,
      'is_castrated': isCastrated,
      'microchip': microchip,
      'photo_url': photoUrl,
      'notes': notes,
    };
  }

  double get weightNum {
    if (weight == null) return 0.0;
    return double.tryParse(weight!.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
  }

  String get speciesLabel => species == 'dog' ? 'Cachorro' : 'Gato';
  String get speciesEmoji => species == 'dog' ? '🐕' : '🐈';
  
  String get sexLabel {
    switch (sex) {
      case 'male': return 'Macho';
      case 'female': return 'Fêmea';
      default: return 'Não informado';
    }
  }

  String get formattedBirthDate {
    if (birthDate == null) return 'Não informado';
    try {
      final date = DateTime.parse(birthDate!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return birthDate!;
    }
  }
}
