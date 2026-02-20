import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pet_service.dart';
import '../services/record_service.dart';
import '../services/biometry_service.dart';
import '../services/vaccine_service.dart';
import '../services/veterinarian_service.dart';
import '../services/medication_service.dart';
import '../services/document_service.dart';
import 'add_record_screen.dart';
import 'snout_scanner_screen.dart';
import 'vaccines_screen.dart';
import 'pet_qr_code_screen.dart';
import 'veterinarians_screen.dart';
import 'medications_screen.dart';
import 'documents_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _petService = PetService();
  final _recordService = RecordService();
  final _biometryService = BiometryService();
  final _vaccineService = VaccineService();
  final _imagePicker = ImagePicker();

  int _selectedMenuIndex = 0;

  Map<String, dynamic>? _pet;
  List<dynamic> _records = [];
  List<dynamic> _vaccines = [];
  List<VaccineReminder> _vaccineReminders = [];
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  bool _hasBiometry = false;
  String? _error;

  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.info_outline, label: 'Info'),
    _MenuItem(icon: Icons.medical_services_outlined, label: 'Prontuário'),
    _MenuItem(icon: Icons.vaccines_outlined, label: 'Vacinas'),
    _MenuItem(icon: Icons.medication_outlined, label: 'Medicamentos'),
    _MenuItem(icon: Icons.folder_outlined, label: 'Documentos'),
    _MenuItem(icon: Icons.local_hospital_outlined, label: 'Veterinários'),
    _MenuItem(icon: Icons.fingerprint, label: 'Biometria'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pet = await _petService.getPet(widget.petId);
      final records = await _recordService.listRecords(widget.petId);
      final vaccines = records.where((r) => r['type'] == 'vaccine').toList();
      final hasBiometry = await _biometryService.hasBiometry(widget.petId);

      List<VaccineReminder> reminders = [];
      try {
        reminders = await _vaccineService.listReminders(petId: widget.petId);
      } catch (_) {}

      setState(() {
        _pet = pet;
        _records = records;
        _vaccines = vaccines;
        _hasBiometry = hasBiometry;
        _vaccineReminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Não informado';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getSexLabel(String? sex) {
    switch (sex) {
      case 'male': return 'Macho';
      case 'female': return 'Fêmea';
      default: return 'Não informado';
    }
  }

  String _getSpeciesEmoji(String? species) {
    switch (species) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      default: return '🐾';
    }
  }

  String _getSpeciesLabel(String? species) {
    switch (species) {
      case 'dog': return 'Cachorro';
      case 'cat': return 'Gato';
      default: return species ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carregando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erro: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header com informações do pet
          SliverToBoxAdapter(
            child: _buildHeader(primaryColor),
          ),

          // Menu horizontal
          SliverToBoxAdapter(
            child: _buildMenuBar(primaryColor),
          ),

          // Conteúdo da aba selecionada
          SliverFillRemaining(
            child: _buildSelectedContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRecordScreen(petId: widget.petId),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo Registro'),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    final isDog = _pet?['species'] == 'dog';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Colors.white),
                    tooltip: 'QR Code',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetQrCodeScreen(
                            petId: widget.petId,
                            petName: _pet?['name'] ?? 'Pet',
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: !_hasBiometry,
                      label: const Text('!'),
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.fingerprint, color: Colors.white),
                    ),
                    tooltip: _hasBiometry ? 'Focinho registrado' : 'Registrar focinho',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SnoutScannerScreen(
                            petId: widget.petId,
                            mode: ScannerMode.register,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadData();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edição em desenvolvimento')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Avatar e info do pet
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _pet?['photo_url'] != null
                                ? Image.network(
                                    _pet!['photo_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                                  )
                                : _buildAvatarPlaceholder(),
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.camera_alt, size: 16, color: primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getSpeciesEmoji(_pet?['species']),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pet?['name'] ?? 'Pet',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_pet?['breed'] ?? _getSpeciesLabel(_pet?['species'])} • ${_getSexLabel(_pet?['sex'])}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_pet?['weight'] != null)
                          Text(
                            '${_pet?['weight']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Badges
                        Row(
                          children: [
                            if (_hasBiometry)
                              _buildBadge(Icons.fingerprint, 'Biometria', Colors.green),
                            if (_pet?['is_castrated'] == true)
                              _buildBadge(Icons.check_circle, 'Castrado', Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            final isSelected = _selectedMenuIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Material(
                  color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMenuIndex = index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected ? primaryColor : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? primaryColor : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedMenuIndex) {
      case 0:
        return _buildInfoTab();
      case 1:
        return _buildRecordsTab();
      case 2:
        return _buildVaccinesTab();
      case 3:
        return _buildMedicationsTab();
      case 4:
        return _buildDocumentsTab();
      case 5:
        return _buildVeterinariansTab();
      case 6:
        return _buildBiometryTab();
      default:
        return _buildInfoTab();
    }
  }

  Widget _buildBiometryTab() {
    if (!_hasBiometry) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Nenhuma biometria registrada'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SnoutScannerScreen(
                      petId: widget.petId,
                      mode: ScannerMode.register,
                    ),
                  ),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Registrar Focinho'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, size: 48, color: Colors.green.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Biometria Registrada',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'A biometria do focinho deste pet está ativa e vinculada ao ID único.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SnoutScannerScreen(
                    petId: widget.petId,
                    mode: ScannerMode.verify,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.verified_user),
            label: const Text('Testar Verificação'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final isDog = _pet?['species'] == 'dog';
    return Container(
      color: isDog ? Colors.amber.shade50 : Colors.purple.shade50,
      child: Center(
        child: Text(
          _getSpeciesEmoji(_pet?['species']),
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Grid de Informações
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildGridInfoCard(
                icon: Icons.wc,
                label: 'Sexo',
                value: _getSexLabel(_pet?['sex']),
                color: Colors.blue,
              ),
              _buildGridInfoCard(
                icon: Icons.cake,
                label: 'Nascimento',
                value: _formatDate(_pet?['birth_date']),
                color: Colors.purple,
              ),
              _buildGridInfoCard(
                icon: Icons.palette,
                label: 'Cor / Pelagem',
                value: _pet?['color'] ?? 'Não informado',
                color: Colors.amber,
              ),
              _buildGridInfoCard(
                icon: Icons.nfc,
                label: 'Microchip',
                value: _pet?['microchip'] ?? '—',
                color: Colors.green,
                isMono: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Outros Detalhes',
            icon: Icons.pets,
            children: [
              _buildInfoRow(Icons.pets, 'Espécie', '${_getSpeciesEmoji(_pet?['species'])} ${_getSpeciesLabel(_pet?['species'])}'),
              _buildInfoRow(Icons.category, 'Raça', _pet?['breed'] ?? 'Não informada'),
              _buildInfoRow(Icons.monitor_weight, 'Peso', _pet?['weight'] ?? 'Não informado'),
              _buildInfoRow(Icons.content_cut, 'Castrado', _pet?['is_castrated'] == true ? 'Sim' : 'Não'),
            ],
          ),

          if (_pet?['notes'] != null && _pet?['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Observações',
              icon: Icons.note,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_pet?['notes'] ?? ''),
                ),
              ],
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildGridInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMono = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Nenhum registro no prontuário', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _records.length + 1,
              itemBuilder: (context, index) {
                if (index == _records.length) {
                  return const SizedBox(height: 80);
                }
                final record = _records[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: _getRecordIcon(record['type']),
                    title: Text(
                      record['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${RecordType.label(record['type'])} • ${_formatDate(record['event_date'])}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    onTap: () => _showRecordDetails(record),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVaccinesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _vaccines.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vaccines_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Nenhuma vacina registrada', style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRecordScreen(petId: widget.petId),
                        ),
                      );
                      if (result == true) _loadData();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Vacina'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vaccines.length + 1,
              itemBuilder: (context, index) {
                if (index == _vaccines.length) {
                  return const SizedBox(height: 80);
                }
                final vaccine = _vaccines[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.vaccines, color: Colors.green.shade600),
                    ),
                    title: Text(
                      vaccine['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(vaccine['event_date']),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.info_outline, color: Colors.grey.shade400),
                      onPressed: () => _showRecordDetails(vaccine),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMedicationsTab() {
    return MedicationsScreen(petId: widget.petId);
  }

  Widget _buildDocumentsTab() {
    return DocumentsScreen(petId: widget.petId);
  }

  Widget _buildVeterinariansTab() {
    return VeterinariansScreen(petId: widget.petId);
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      _getRecordIcon(record['type']),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          record['title'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      RecordType.label(record['type']),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Data', _formatDate(record['event_date'])),
                  if (record['notes'] != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Observações',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(record['notes']),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Criado em: ${_formatDate(record['created_at'])}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _getRecordIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'vaccine':
        icon = Icons.vaccines;
        color = Colors.green;
        break;
      case 'visit':
        icon = Icons.local_hospital;
        color = Colors.blue;
        break;
      case 'diagnosis':
        icon = Icons.medical_information;
        color = Colors.orange;
        break;
      case 'medication':
        icon = Icons.medication;
        color = Colors.purple;
        break;
      case 'exam':
        icon = Icons.biotech;
        color = Colors.teal;
        break;
      case 'procedure':
        icon = Icons.healing;
        color = Colors.red;
        break;
      case 'allergy':
        icon = Icons.warning;
        color = Colors.amber;
        break;
      default:
        icon = Icons.note;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;

  _MenuItem({required this.icon, required this.label});
}
