import 'package:flutter/material.dart';
import '../services/pet_service.dart';

class AddPetScreen extends StatefulWidget {
  final Map<String, dynamic>? pet;

  const AddPetScreen({super.key, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petService = PetService();
  
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  late final TextEditingController _microchipController;
  late final TextEditingController _notesController;
  
  String _species = 'dog';
  String _sex = 'unknown';
  bool _isCastrated = false;
  DateTime? _birthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    
    _nameController = TextEditingController(text: pet?['name'] ?? '');
    _breedController = TextEditingController(text: pet?['breed'] ?? '');
    _weightController = TextEditingController(text: pet?['weight'] ?? '');
    _microchipController = TextEditingController(text: pet?['microchip'] ?? '');
    _notesController = TextEditingController(text: pet?['notes'] ?? '');
    
    if (pet != null) {
      _species = pet['species'] ?? 'dog';
      _sex = pet['sex'] ?? 'unknown';
      _isCastrated = pet['is_castrated'] ?? false;
      if (pet['birth_date'] != null) {
        try {
          _birthDate = DateTime.parse(pet['birth_date']);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final petData = {
        'name': _nameController.text.trim(),
        'species': _species,
        'breed': _breedController.text.trim().isNotEmpty ? _breedController.text.trim() : null,
        'sex': _sex,
        'birth_date': _birthDate?.toIso8601String().split('T').first,
        'weight': _weightController.text.trim().isNotEmpty ? _weightController.text.trim() : null,
        'is_castrated': _isCastrated,
        'microchip': _microchipController.text.trim().isNotEmpty ? _microchipController.text.trim() : null,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      };

      if (widget.pet != null) {
        await _petService.updatePet(widget.pet!['id'], petData);
      } else {
        await _petService.createPet(
          name: petData['name'] as String,
          species: petData['species'] as String,
          breed: petData['breed'] as String?,
          sex: petData['sex'] as String?,
          birthDate: petData['birth_date'] as String?,
          weight: petData['weight'] as String?,
          isCastrated: petData['is_castrated'] as bool,
          microchip: petData['microchip'] as String?,
          notes: petData['notes'] as String?,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.pet != null ? 'Pet atualizado com sucesso!' : 'Pet cadastrado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Pet' : 'Novo Pet'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                prefixIcon: Icon(Icons.pets),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome do pet';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Espécie
            DropdownButtonFormField<String>(
              value: _species,
              decoration: const InputDecoration(
                labelText: 'Espécie *',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'dog', child: Text('Cachorro')),
                DropdownMenuItem(value: 'cat', child: Text('Gato')),
              ],
              onChanged: (value) {
                setState(() => _species = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // Raça
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(
                labelText: 'Raça',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 16),
            
            // Sexo
            DropdownButtonFormField<String>(
              value: _sex,
              decoration: const InputDecoration(
                labelText: 'Sexo',
                prefixIcon: Icon(Icons.wc),
              ),
              items: const [
                DropdownMenuItem(value: 'unknown', child: Text('Não informado')),
                DropdownMenuItem(value: 'male', child: Text('Macho')),
                DropdownMenuItem(value: 'female', child: Text('Fêmea')),
              ],
              onChanged: (value) {
                setState(() => _sex = value!);
              },
            ),
            const SizedBox(height: 16),
            
            // Data de nascimento
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake),
              title: Text(
                _birthDate != null
                    ? 'Nascimento: ${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                    : 'Data de nascimento',
              ),
              trailing: TextButton(
                onPressed: _selectBirthDate,
                child: const Text('Selecionar'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Peso
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Peso',
                prefixIcon: Icon(Icons.monitor_weight),
                hintText: 'Ex: 10kg',
              ),
            ),
            const SizedBox(height: 16),
            
            // Castrado
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Castrado'),
              value: _isCastrated,
              onChanged: (value) {
                setState(() => _isCastrated = value);
              },
            ),
            const SizedBox(height: 16),
            
            // Microchip
            TextFormField(
              controller: _microchipController,
              decoration: const InputDecoration(
                labelText: 'Microchip',
                prefixIcon: Icon(Icons.memory),
              ),
            ),
            const SizedBox(height: 16),
            
            // Observações
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Botão salvar
            ElevatedButton(
              onPressed: _isLoading ? null : _savePet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(isEditing ? 'Salvar Alterações' : 'Salvar Pet'),
            ),
          ],
        ),
      ),
    );
  }
}

