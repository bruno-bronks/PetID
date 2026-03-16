import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/lost_pet_service.dart';
import '../services/pet_service.dart';
import '../services/api_service.dart';

class ReportLostPetScreen extends StatefulWidget {
  final String reportType; // 'lost' ou 'found'
  final Position? currentPosition;

  const ReportLostPetScreen({
    super.key,
    required this.reportType,
    this.currentPosition,
  });

  @override
  State<ReportLostPetScreen> createState() => _ReportLostPetScreenState();
}

class _ReportLostPetScreenState extends State<ReportLostPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lostPetService = LostPetService();
  final _petService = PetService();
  final _apiService = ApiService();
  
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<dynamic> _myPets = [];
  List<LostPetReport> _lostPetsNearby = [];
  int? _selectedPetId;
  int? _selectedLostPetId; // Pet perdido selecionado (para "encontrado")
  String _foundSpecies = 'dog';
  String? _foundBreed;
  String? _foundColor;
  DateTime _eventDate = DateTime.now();
  bool _contactVisible = true;
  bool _isLoading = false;
  bool _isLoadingPets = true;
  bool _isLoadingLostPets = false;

  bool get isLostReport => widget.reportType == 'lost';

  @override
  void initState() {
    super.initState();
    if (isLostReport) {
      _loadMyPets();
    } else {
      _isLoadingPets = false;
      _loadLostPetsNearby();
    }
  }

  Future<void> _loadMyPets() async {
    try {
      final pets = await _petService.listPets();
      setState(() {
        _myPets = pets;
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() => _isLoadingPets = false);
    }
  }

  Future<void> _loadLostPetsNearby() async {
    setState(() => _isLoadingLostPets = true);
    
    try {
      // Usa posição atual ou coordenadas padrão (centro do Brasil)
      final lat = widget.currentPosition?.latitude ?? -15.7801;
      final lng = widget.currentPosition?.longitude ?? -47.9292;
      
      final reports = await _lostPetService.getNearby(
        latitude: lat,
        longitude: lng,
        radiusKm: 5000, // Raio muito grande para encontrar todos os pets
        reportType: 'lost', // Apenas pets perdidos
      );
      
      if (mounted) {
        setState(() {
          _lostPetsNearby = reports;
          _isLoadingLostPets = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLostPets = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (isLostReport && _selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o pet')),
      );
      return;
    }

    if (widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Localização não disponível')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLostReport) {
        await _lostPetService.reportLost(
          petId: _selectedPetId!,
          latitude: widget.currentPosition!.latitude,
          longitude: widget.currentPosition!.longitude,
          address: _addressController.text.trim().isNotEmpty 
              ? _addressController.text.trim() : null,
          city: _cityController.text.trim().isNotEmpty 
              ? _cityController.text.trim() : null,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() : null,
          contactPhone: _phoneController.text.trim().isNotEmpty 
              ? _phoneController.text.trim() : null,
          contactVisible: _contactVisible,
          eventDate: _eventDate,
        );
      } else {
        await _lostPetService.reportFound(
          latitude: widget.currentPosition!.latitude,
          longitude: widget.currentPosition!.longitude,
          species: _foundSpecies,
          breed: _foundBreed,
          color: _foundColor,
          address: _addressController.text.trim().isNotEmpty 
              ? _addressController.text.trim() : null,
          city: _cityController.text.trim().isNotEmpty 
              ? _cityController.text.trim() : null,
          description: _descriptionController.text.trim().isNotEmpty 
              ? _descriptionController.text.trim() : null,
          contactPhone: _phoneController.text.trim().isNotEmpty 
              ? _phoneController.text.trim() : null,
          contactVisible: _contactVisible,
          eventDate: _eventDate,
          petId: _selectedLostPetId, // Pet perdido identificado
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLostReport 
                ? 'Reporte criado! Esperamos que encontre seu pet logo.' 
                : 'Obrigado por ajudar! O dono será notificado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isLostReport ? 'Reportar Pet Perdido' : 'Reportar Pet Encontrado'),
        backgroundColor: isLostReport ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPets
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Alerta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isLostReport ? Colors.red : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isLostReport ? Icons.warning : Icons.favorite,
                          color: isLostReport ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isLostReport
                                ? 'Seu reporte será visível para pessoas próximas que podem ajudar.'
                                : 'Obrigado por ajudar! O dono poderá ver seu reporte.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seleção do pet (se perdido)
                  if (isLostReport) ...[
                    const Text('Qual pet você perdeu?', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_myPets.isEmpty)
                      const Text('Você não tem pets cadastrados',
                          style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _myPets.map((pet) {
                          final isSelected = _selectedPetId == pet['id'];
                          return ChoiceChip(
                            label: Text(pet['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedPetId = selected ? pet['id'] : null);
                            },
                            selectedColor: Colors.red.shade100,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Dados do pet encontrado
                  if (!isLostReport) ...[
                    const Text('Que tipo de pet você encontrou?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🐕'),
                                SizedBox(width: 4),
                                Text('Cachorro'),
                              ],
                            ),
                            selected: _foundSpecies == 'dog',
                            onSelected: (selected) {
                              setState(() {
                                _foundSpecies = 'dog';
                                _selectedLostPetId = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🐈'),
                                SizedBox(width: 4),
                                Text('Gato'),
                              ],
                            ),
                            selected: _foundSpecies == 'cat',
                            onSelected: (selected) {
                              setState(() {
                                _foundSpecies = 'cat';
                                _selectedLostPetId = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Lista de pets perdidos da espécie selecionada
                    _buildLostPetsList(),
                    
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Raça (se souber)',
                        prefixIcon: Icon(Icons.pets),
                      ),
                      onChanged: (value) => _foundBreed = value.trim().isNotEmpty ? value.trim() : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cor/Pelagem',
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                      onChanged: (value) => _foundColor = value.trim().isNotEmpty ? value.trim() : null,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Data
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(isLostReport ? 'Quando perdeu?' : 'Quando encontrou?'),
                    subtitle: Text(_formatDate(_eventDate)),
                    trailing: TextButton(
                      onPressed: _selectDate,
                      child: const Text('Alterar'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Localização
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço/Local',
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'Ex: Praça Central, Rua das Flores',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descrição
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      prefixIcon: const Icon(Icons.description),
                      hintText: isLostReport
                          ? 'Detalhes que ajudem a identificar'
                          : 'Como/onde encontrou, estado do pet',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Contato
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone para contato',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mostrar telefone publicamente'),
                    subtitle: const Text('Se desativado, será parcialmente oculto'),
                    value: _contactVisible,
                    onChanged: (value) => setState(() => _contactVisible = value),
                  ),
                  const SizedBox(height: 24),

                  // Botão
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLostReport ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLostReport ? 'Publicar Alerta' : 'Publicar'),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildLostPetsList() {
    // Filtra pets perdidos pela espécie selecionada
    final filteredPets = _lostPetsNearby
        .where((p) => (p.petSpecies ?? p.foundSpecies) == _foundSpecies)
        .toList();
    
    if (_isLoadingLostPets) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Debug: mostra quantos pets foram carregados
    if (_lostPetsNearby.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nenhum pet reportado como perdido no momento.',
                style: TextStyle(color: Colors.blue.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    
    if (filteredPets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nenhum ${_foundSpecies == 'dog' ? 'cachorro' : 'gato'} reportado como perdido. (${_lostPetsNearby.length} pets de outras espécies)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.pets, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reconhece algum desses pets perdidos?',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...filteredPets.map((pet) => _buildLostPetCard(pet)),
      ],
    );
  }

  Widget _buildLostPetCard(LostPetReport pet) {
    final isSelected = _selectedLostPetId == pet.petId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_selectedLostPetId == pet.petId) {
              _selectedLostPetId = null; // Desmarcar
            } else {
              _selectedLostPetId = pet.petId;
              _foundBreed = pet.petBreed;
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto ou ícone
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: pet.petPhotoUrl != null 
                    ? NetworkImage(_apiService.getFullUrl(pet.petPhotoUrl!)) 
                    : null,
                child: pet.petPhotoUrl == null
                    ? Icon(Icons.pets, color: Colors.grey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.petName ?? 'Pet sem nome',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.petBreed ?? 'Raça desconhecida'} • ${pet.distanceText.isNotEmpty ? pet.distanceText : 'Próximo'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (pet.city != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        pet.city!,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Checkbox/indicador
              if (isSelected)
                const Icon(Icons.check_circle, color: Colors.green, size: 28)
              else
                Icon(Icons.radio_button_off, color: Colors.grey.shade400, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
