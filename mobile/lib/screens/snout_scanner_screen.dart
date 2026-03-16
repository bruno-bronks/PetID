import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/biometry_service.dart';
import '../services/lost_pet_service.dart';
import 'lost_pets_map_screen.dart';

enum ScannerMode { register, search }

class SnoutScannerScreen extends StatefulWidget {
  final int? petId;
  final ScannerMode mode;
  
  const SnoutScannerScreen({
    super.key, 
    this.petId,
    this.mode = ScannerMode.register,
  });

  @override
  State<SnoutScannerScreen> createState() => _SnoutScannerScreenState();
}

class _SnoutScannerScreenState extends State<SnoutScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFrontCamera = false;
  String? _error;
  XFile? _capturedImage;
  final _imagePicker = ImagePicker();
  final _biometryService = BiometryService();
  final _lostPetService = LostPetService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'Nenhuma câmera disponível';
        });
        return;
      }
      
      await _setupCamera(_cameras!.first);
    } catch (e) {
      setState(() {
        _error = 'Erro ao inicializar câmera: $e';
      });
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    _cameraController?.dispose();
    
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao configurar câmera: $e';
      });
    }
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isInitialized = false;
    });
    
    final cameraIndex = _isFrontCamera ? 1 : 0;
    await _setupCamera(_cameras![cameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    setState(() => _isProcessing = true);
    
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _capturedImage = picked;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _processSnout() async {
    if (_capturedImage == null) return;
    
    setState(() => _isProcessing = true);

    try {
      if (widget.mode == ScannerMode.register && widget.petId != null) {
        await _registerBiometry();
      } else {
        await _searchBySnout();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _registerBiometry() async {
    final result = await _biometryService.registerSnout(
      petId: widget.petId!,
      imagePath: _capturedImage!.path,
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Focinho Registrado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O padrão biométrico do focinho foi capturado com sucesso.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fingerprint, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ID Biométrico gerado',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Qualidade: ${result['quality_score'] ?? 0}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Concluir'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _searchBySnout() async {
    final result = await _biometryService.searchBySnout(
      imagePath: _capturedImage!.path,
      threshold: 0.7,
      maxResults: 5,
    );

    if (mounted) {
      if (result.found) {
        _showSearchResults(result);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.search_off, color: Colors.orange),
                SizedBox(width: 8),
                Text('Nenhum Pet Encontrado'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(result.message),
                const SizedBox(height: 16),
                const Text(
                  'Dicas:\n• Tire uma foto mais próxima\n• Melhore a iluminação\n• Centralize o focinho',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _retakePhoto();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSearchResults(BiometrySearchResponse result) async {
    // Verificar se algum pet encontrado está perdido
    List<LostPetReport> lostReports = [];
    try {
      final allLostPets = await _lostPetService.getNearby(
        latitude: 0,
        longitude: 0,
        radiusKm: 50000, // Busca global
        reportType: 'lost',
      );
      
      // Filtrar por pets que correspondem aos resultados
      for (final pet in result.results) {
        final matchingLost = allLostPets.where((r) => 
          r.petId == pet.petId && r.status == 'active'
        ).toList();
        lostReports.addAll(matchingLost);
      }
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lostReports.isNotEmpty 
                    ? Colors.red.shade50 
                    : Colors.green.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        lostReports.isNotEmpty ? Icons.warning : Icons.check_circle, 
                        color: lostReports.isNotEmpty ? Colors.red : Colors.green.shade600, 
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lostReports.isNotEmpty 
                                  ? '🚨 PET PERDIDO ENCONTRADO!'
                                  : 'Pet Encontrado!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: lostReports.isNotEmpty ? Colors.red : null,
                              ),
                            ),
                            Text(
                              lostReports.isNotEmpty
                                  ? 'Este pet foi reportado como perdido!'
                                  : result.message,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Alerta de pet perdido
            if (lostReports.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ATENÇÃO: Este pet está sendo procurado!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O dono deste pet está procurando por ele. Entre em contato para ajudar!',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LostPetsMapScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Ver Mapa de Perdidos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: result.results.length,
                itemBuilder: (context, index) {
                  final pet = result.results[index];
                  final isLost = lostReports.any((r) => r.petId == pet.petId);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isLost ? Colors.red.shade50 : null,
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: pet.species == 'dog' 
                                ? Colors.brown.shade100 
                                : Colors.orange.shade100,
                            child: Icon(
                              Icons.pets,
                              color: pet.species == 'dog' 
                                  ? Colors.brown 
                                  : Colors.orange,
                            ),
                          ),
                          if (isLost)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Text(
                            pet.petName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isLost) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PERDIDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pet.speciesLabel}${pet.breed != null ? ' - ${pet.breed}' : ''}'),
                          if (pet.ownerName != null)
                            Text(
                              'Tutor: ${pet.ownerName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (pet.ownerPhone != null)
                            Text(
                              'Tel: ${pet.ownerPhone}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSimilarityColor(pet.similarityPercent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pet.similarityPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => _showPetDetails(pet),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSimilarityColor(int percent) {
    if (percent >= 90) return Colors.green;
    if (percent >= 80) return Colors.lightGreen;
    if (percent >= 70) return Colors.orange;
    return Colors.red;
  }

  void _showPetDetails(PetSearchResult pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pet.petName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.pets, 'Espécie', pet.speciesLabel),
            if (pet.breed != null)
              _buildDetailRow(Icons.category, 'Raça', pet.breed!),
            _buildDetailRow(Icons.percent, 'Similaridade', '${pet.similarityPercent}%'),
            const Divider(),
            if (pet.ownerName != null)
              _buildDetailRow(Icons.person, 'Tutor', pet.ownerName!),
            if (pet.ownerPhone != null)
              _buildDetailRow(Icons.phone, 'Telefone', pet.ownerPhone!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          if (pet.ownerPhone != null)
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Abrir app de telefone
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ligar para ${pet.ownerPhone}')),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Ligar'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearchMode = widget.mode == ScannerMode.search;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(isSearchMode ? 'Buscar Pet' : 'Scanner de Focinho'),
        actions: [
          if (_cameras != null && _cameras!.length > 1 && _capturedImage == null)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _toggleCamera,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Usar Galeria'),
            ),
          ],
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildPreview();
    }

    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return _buildCamera();
  }

  Widget _buildCamera() {
    final isSearchMode = widget.mode == ScannerMode.search;
    
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        
        // Overlay com guia
        Positioned.fill(
          child: CustomPaint(
            painter: SnoutGuidePainter(isSearch: isSearchMode),
          ),
        ),
        
        // Instruções
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isSearchMode
                  ? '🔍 Escaneie o focinho para encontrar o dono\n'
                    '📸 Tire uma foto clara do focinho'
                  : '📸 Posicione o focinho do pet dentro do círculo\n'
                    '💡 Certifique-se de boa iluminação\n'
                    '🎯 Mantenha a câmera estável',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        // Botões
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Galeria
              IconButton(
                onPressed: _pickFromGallery,
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.white, size: 28),
                ),
              ),
              
              // Capturar
              GestureDetector(
                onTap: _isProcessing ? null : _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSearchMode ? Colors.orange : Colors.white, 
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSearchMode ? Colors.orange : Colors.white,
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Icon(
                              isSearchMode ? Icons.search : Icons.pets, 
                              size: 32, 
                              color: Colors.black,
                            ),
                    ),
                  ),
                ),
              ),
              
              // Placeholder
              const SizedBox(width: 64),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final isSearchMode = widget.mode == ScannerMode.search;
    
    return Stack(
      children: [
        // Imagem capturada
        Positioned.fill(
          child: Image.file(
            File(_capturedImage!.path),
            fit: BoxFit.cover,
          ),
        ),
        
        // Overlay de análise
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      isSearchMode 
                          ? 'Buscando pet na base de dados...'
                          : 'Analisando padrões do focinho...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSearchMode
                          ? 'Comparando biometria'
                          : 'Gerando ID biométrico único',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Botões de ação
        if (!_isProcessing)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tirar Outra'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _processSnout,
                  icon: Icon(isSearchMode ? Icons.search : Icons.check),
                  label: Text(isSearchMode ? 'Buscar Pet' : 'Registrar Focinho'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSearchMode ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🐾 Como funciona o Scanner de Focinho',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _HelpItem(
              icon: Icons.camera_alt,
              title: 'Capture o Focinho',
              description: 'Tire uma foto clara do focinho do pet, como uma impressão digital única.',
            ),
            const _HelpItem(
              icon: Icons.fingerprint,
              title: 'Padrão Único',
              description: 'Cada focinho tem um padrão único de linhas e texturas, como uma digital humana.',
            ),
            const _HelpItem(
              icon: Icons.search,
              title: 'Identificação',
              description: 'Use o scanner para encontrar pets perdidos ou verificar a identidade.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para desenhar o guia circular no scanner
class SnoutGuidePainter extends CustomPainter {
  final bool isSearch;
  
  SnoutGuidePainter({this.isSearch = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);
    final radius = size.width * 0.35;
    
    // Fundo escuro com buraco
    final bgPaint = Paint()..color = Colors.black54;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);
    
    // Círculo guia
    final guidePaint = Paint()
      ..color = isSearch ? Colors.orange : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, guidePaint);
    
    // Marcadores nos cantos
    final markerLength = 30.0;
    final markerPaint = Paint()
      ..color = isSearch ? Colors.orange : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Top-left
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius + markerLength),
      Offset(center.dx - radius, center.dy - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx - radius + markerLength, center.dy - radius),
      markerPaint,
    );
    
    // Top-right
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius + markerLength),
      Offset(center.dx + radius, center.dy - radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius),
      Offset(center.dx + radius - markerLength, center.dy - radius),
      markerPaint,
    );
    
    // Bottom-left
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius - markerLength),
      Offset(center.dx - radius, center.dy + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy + radius),
      Offset(center.dx - radius + markerLength, center.dy + radius),
      markerPaint,
    );
    
    // Bottom-right
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius - markerLength),
      Offset(center.dx + radius, center.dy + radius),
      markerPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy + radius),
      Offset(center.dx + radius - markerLength, center.dy + radius),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
