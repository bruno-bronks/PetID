import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/pet_service.dart';
import '../services/api_service.dart';
import 'pet_detail_screen.dart';

class PetsListScreen extends StatefulWidget {
  const PetsListScreen({super.key});

  @override
  State<PetsListScreen> createState() => PetsListScreenState();
}

class PetsListScreenState extends State<PetsListScreen> {
  final PetService _petService = PetService();
  List<dynamic> _pets = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;

  static const Color _purple = Color(0xFF7C3AED);
  static const Color _purpleLight = Color(0xFFEDE9FE);

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult == ConnectivityResult.none || 
                        (connectivityResult is List && connectivityResult.every((r) => r == ConnectivityResult.none));
                        
      final pets = await _petService.listPets();
      if (!mounted) return;
      
      setState(() {
        _pets = pets;
        _isOffline = isOffline;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void refresh() {
    _loadPets();
  }

  String _getSpeciesLabel(String? species) {
    switch (species) {
      case 'dog':
        return 'Cachorro';
      case 'cat':
        return 'Gato';
      default:
        return species ?? '';
    }
  }

  String _getSpeciesEmoji(String? species) {
    switch (species) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐈';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _purple),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline,
                    size: 40, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                'Algo deu errado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPets,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _purple.withValues(alpha: 0.15),
                      _purple.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🐾', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nenhum pet cadastrado',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adicione seu primeiro pet\ne comece a cuidar da saúde dele!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque no botão + abaixo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _purple.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            color: Colors.amber.shade200,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Modo Offline (Exibindo dados salvos localmente)',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPets,
            color: _purple,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return _PetCard(
                  pet: pet,
                  speciesLabel: _getSpeciesLabel(pet['species']),
                  speciesEmoji: _getSpeciesEmoji(pet['species']),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetDetailScreen(petId: pet['id']),
                      ),
                    );
                    _loadPets();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String speciesLabel;
  final String speciesEmoji;
  final VoidCallback onTap;

  static const Color _purple = Color(0xFF7C3AED);

  const _PetCard({
    required this.pet,
    required this.speciesLabel,
    required this.speciesEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = pet['photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final fullPhotoUrl =
        hasPhoto ? ApiService().getFullUrl(photoUrl) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(fullPhotoUrl),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF1A1A2E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge de espécie
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$speciesEmoji $speciesLabel',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (pet['breed'] != null &&
                          (pet['breed'] as String).isNotEmpty)
                        Text(
                          pet['breed'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (pet['sex'] != null && pet['sex'] != 'unknown') ...[
                        const SizedBox(height: 2),
                        Text(
                          _sexLabel(pet['sex']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade300, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          photoUrl,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatar(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingAvatar();
          },
        ),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          speciesEmoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF7C3AED),
          ),
        ),
      ),
    );
  }

  String _sexLabel(String? sex) {
    switch (sex) {
      case 'male':
        return 'Macho';
      case 'female':
        return 'Femea';
      default:
        return '';
    }
  }
}
