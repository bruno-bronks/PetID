import 'package:flutter/material.dart';
import '../services/pet_service.dart';

import '../models/pet.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;

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
  late final TextEditingController _colorController;
  late final TextEditingController _notesController;

  String _species = 'dog';
  String _sex = 'unknown';
  bool _isCastrated = false;
  DateTime? _birthDate;
  bool _isLoading = false;

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);
  static const Color _fieldFill = Color(0xFFF5F3FF);

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;

    _nameController = TextEditingController(text: pet?.name ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _weightController = TextEditingController(text: pet?.weight ?? '');
    _microchipController =
        TextEditingController(text: pet?.microchip ?? '');
    _colorController = TextEditingController(text: pet?.color ?? '');
    _notesController = TextEditingController(text: pet?.notes ?? '');

    if (pet != null) {
      _species = pet.species;
      _sex = pet.sex ?? 'unknown';
      _isCastrated = pet.isCastrated;
      if (pet.birthDate != null) {
        try {
          _birthDate = DateTime.parse(pet.birthDate!);
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
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _purple),
        ),
        child: child!,
      ),
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
        'breed': _breedController.text.trim().isNotEmpty
            ? _breedController.text.trim()
            : null,
        'sex': _sex,
        'birth_date': _birthDate?.toIso8601String().split('T').first,
        'weight': _weightController.text.trim().isNotEmpty
            ? _weightController.text.trim()
            : null,
        'is_castrated': _isCastrated,
        'color': _colorController.text.trim().isNotEmpty
            ? _colorController.text.trim()
            : null,
        'microchip': _microchipController.text.trim().isNotEmpty
            ? _microchipController.text.trim()
            : null,
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      };

      if (widget.pet != null) {
        await _petService.updatePet(widget.pet!.id, petData);
      } else {
        await _petService.createPet(
          name: petData['name'] as String,
          species: petData['species'] as String,
          breed: petData['breed'] as String?,
          sex: petData['sex'] as String?,
          birthDate: petData['birth_date'] as String?,
          weight: petData['weight'] as String?,
          isCastrated: petData['is_castrated'] as bool,
          color: petData['color'] as String?,
          microchip: petData['microchip'] as String?,
          notes: petData['notes'] as String?,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.pet != null
                ? 'Pet atualizado com sucesso!'
                : 'Pet cadastrado com sucesso!'),
            backgroundColor: _purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _purple, size: 20),
      filled: true,
      fillColor: _fieldFill,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: color.withValues(alpha: 0.2), thickness: 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? 'Editar Pet' : 'Novo Pet',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // --- Secao: Informacoes Basicas ---
            _buildSectionHeader(
                'Informacoes Basicas', Icons.info_outline, _purple),

            // Nome
            TextFormField(
              controller: _nameController,
              decoration: _fieldDecoration(
                label: 'Nome do Pet *',
                icon: Icons.pets,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o nome do pet';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Seletor de especie com cards visuais
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Especie *',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _SpeciesCard(
                        emoji: '🐕',
                        label: 'Cachorro',
                        value: 'dog',
                        selected: _species == 'dog',
                        onTap: () => setState(() => _species = 'dog'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SpeciesCard(
                        emoji: '🐈',
                        label: 'Gato',
                        value: 'cat',
                        selected: _species == 'cat',
                        onTap: () => setState(() => _species = 'cat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Raca
            TextFormField(
              controller: _breedController,
              decoration: _fieldDecoration(
                label: 'Raca',
                icon: Icons.badge,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 28),

            // --- Secao: Caracteristicas ---
            _buildSectionHeader(
                'Caracteristicas', Icons.favorite_outline, Colors.pink.shade400),

            // Sexo com chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Sexo',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    _SexChip(
                      label: 'Macho',
                      icon: Icons.male,
                      value: 'male',
                      selected: _sex == 'male',
                      color: Colors.blue.shade400,
                      onTap: () => setState(() => _sex = 'male'),
                    ),
                    _SexChip(
                      label: 'Femea',
                      icon: Icons.female,
                      value: 'female',
                      selected: _sex == 'female',
                      color: Colors.pink.shade400,
                      onTap: () => setState(() => _sex = 'female'),
                    ),
                    _SexChip(
                      label: 'Nao informado',
                      icon: Icons.help_outline,
                      value: 'unknown',
                      selected: _sex == 'unknown',
                      color: Colors.grey.shade500,
                      onTap: () => setState(() => _sex = 'unknown'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cor / Pelagem
            TextFormField(
              controller: _colorController,
              decoration: _fieldDecoration(
                label: 'Cor / Pelagem',
                icon: Icons.palette_outlined,
                hint: 'Ex: Preto e Branco, Caramelo',
              ),
            ),
            const SizedBox(height: 14),

            // Data de nascimento
            GestureDetector(
              onTap: _selectBirthDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, color: _purple, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data de nascimento',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _birthDate != null
                                ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
                                : 'Toque para selecionar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _birthDate != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: _birthDate != null
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Peso
            TextFormField(
              controller: _weightController,
              decoration: _fieldDecoration(
                label: 'Peso',
                icon: Icons.monitor_weight_outlined,
                hint: 'Ex: 10kg',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 14),

            // Castrado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isCastrated
                    ? _purple.withValues(alpha: 0.06)
                    : _fieldFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCastrated ? _purple.withValues(alpha: 0.3) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: _isCastrated ? _purple : Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Castrado(a)',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: _isCastrated
                                ? _purple
                                : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          _isCastrated ? 'Sim' : 'Nao',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCastrated
                                ? _purple.withValues(alpha: 0.7)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isCastrated,
                    onChanged: (value) =>
                        setState(() => _isCastrated = value),
                    activeColor: _purple,
                    activeTrackColor: _purpleLight,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- Secao: Identificacao ---
            _buildSectionHeader('Identificacao',
                Icons.qr_code_2_outlined, Colors.teal.shade500),

            // Microchip
            TextFormField(
              controller: _microchipController,
              decoration: _fieldDecoration(
                label: 'Microchip',
                icon: Icons.memory_outlined,
                hint: 'Numero do microchip',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            // Observacoes
            TextFormField(
              controller: _notesController,
              decoration: _fieldDecoration(
                label: 'Observacoes',
                icon: Icons.notes_outlined,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Botao salvar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing ? Icons.save_outlined : Icons.pets,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEditing ? 'Salvar Alteracoes' : 'Cadastrar Pet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  static const Color _purple = Color(0xFF7C3AED);

  const _SpeciesCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _purple.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _purple : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? _purple : Colors.grey.shade600,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _purple,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SexChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SexChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? color : Colors.grey.shade500),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
