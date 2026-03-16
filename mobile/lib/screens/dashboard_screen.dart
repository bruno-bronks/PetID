import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/pet_service.dart';
import '../services/vaccine_service.dart';
import '../services/lost_pet_service.dart';
import '../services/notification_service.dart';
import '../services/sos_service.dart';
import '../models/pet.dart';
import 'pet_detail_screen.dart';
import 'vaccines_screen.dart';
import 'ai_chat_screen.dart';
import 'lost_pets_map_screen.dart';
import 'health_exam_analysis_screen.dart';
import 'nutrition_scan_screen.dart';
import 'travel_planner_screen.dart';
import 'services_directory_screen.dart';
import 'behavioral_analysis_screen.dart';
import 'blood_donor_network_screen.dart';
import 'iot_hub_screen.dart';
import 'legacy_planner_screen.dart';
import 'snout_scanner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _petService = PetService();
  final _vaccineService = VaccineService();
  final _lostPetService = LostPetService();
  final _apiService = ApiService();

  List<Pet> _pets = [];
  UpcomingVaccines? _vaccines;
  List<LostPetReport> _myLostPets = [];
  List<LostPetReport> _nearbyLostPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final pets = await _petService.listPets();
      UpcomingVaccines? vaccines;
      List<LostPetReport> lostPets = [];
      
      try {
        vaccines = await _vaccineService.getUpcomingVaccines(daysAhead: 30);
      } catch (_) {}
      
      try {
        final myReports = await _lostPetService.getMyReports();
        lostPets = myReports.where((r) => r.status == 'active' && r.isLost).toList();
      } catch (_) {}

      List<LostPetReport> nearbyLost = [];
      try {
        nearbyLost = await _lostPetService.getNearby(
          latitude: -23.5505, // Mock coords for SP
          longitude: -46.6333,
          radiusKm: 10,
          reportType: 'lost',
        );
      } catch (_) {}
      
      if (mounted) {
        setState(() {
          _pets = pets;
          _vaccines = vaccines;
          _myLostPets = lostPets;
          _nearbyLostPets = nearbyLost;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Theme.of(context).colorScheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  if (_vaccines != null && _vaccines!.hasOverdue)
                    _buildAlertCard(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.red,
                      title: '${_vaccines!.overdue.length} vacina(s) atrasada(s)!',
                      subtitle: _vaccines!.overdue.map((v) => v.vaccineName).join(', '),
                      onTap: () => _navigateToVaccines(),
                    ),
                  if (_myLostPets.isNotEmpty)
                    _buildAlertCard(
                      icon: Icons.location_searching,
                      color: Colors.orange,
                      title: '${_myLostPets.length} pet(s) perdido(s)',
                      subtitle: _myLostPets.map((p) => p.displayName).join(', '),
                      onTap: null,
                    ),
                  const SizedBox(height: 8),
                  _buildAiAssistantCard(),
                  const SizedBox(height: 16),
                  _buildLifestyleFeatures(),
                  const SizedBox(height: 16),
                  _buildFrontierFeatures(),
                  const SizedBox(height: 16),
                  if (_nearbyLostPets.isNotEmpty) ...[
                    _buildNearbyLostPetsSection(),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle('🐾 Meus Pets'),
                  const SizedBox(height: 12),
                  _buildPetsList(),
                  const SizedBox(height: 24),
                  _buildNotificationCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour < 12) {
      greeting = 'Bom dia!';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Boa tarde!'; // TODO: Add to l10n
      emoji = '🌤️';
    } else {
      greeting = 'Boa noite!'; // TODO: Add to l10n
      emoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $greeting',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _pets.isEmpty 
                      ? 'Cadastre seu primeiro pet!'
                      : '${_pets.length} ${_pets.length == 1 ? 'pet' : 'pets'} sob seus cuidados',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pets,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final sosService = Provider.of<SosService>(context);
    
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              icon: Icons.vaccines,
              value: '${_vaccines?.totalPending ?? 0}',
              label: 'Vacinas\nPendentes',
              color: Colors.blue,
              onTap: () => _navigateToVaccines(),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.warning_rounded,
              value: '${_vaccines?.overdue.length ?? 0}',
              label: 'Vacinas\nAtrasadas',
              color: Colors.red,
              onTap: () => _navigateToVaccines(),
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Icons.notifications_active,
              value: 'SOS',
              label: sosService.isSosActive ? 'Ativo' : 'Pânico',
              color: Colors.red.shade900,
              onTap: () => _showSosDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color.shade700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color.withOpacity(0.5),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyLostPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🚨 Pets Perdidos na Região'),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _nearbyLostPets.length,
            itemBuilder: (context, index) {
              final report = _nearbyLostPets[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  color: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LostPetsMapScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              image: report.petPhotoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_apiService.getFullUrl(report.petPhotoUrl!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: report.petPhotoUrl == null
                                ? Icon(Icons.pets, color: Colors.red.shade300)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  report.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  report.address ?? 'Localização não informada',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ver no mapa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade900,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🌟 Estilo de Vida Pet'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildLifestyleCard(
              title: 'Análise de Exames',
              subtitle: 'IA Médica',
              icon: Icons.analytics_outlined,
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthExamAnalysisScreen())),
            ),
            _buildLifestyleCard(
              title: 'Nutrição Scan',
              subtitle: 'Smart Diet',
              icon: Icons.restaurant_menu,
              color: Colors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionScanScreen())),
            ),
            _buildLifestyleCard(
              title: 'Viagens',
              subtitle: 'Passaporte',
              icon: Icons.flight_takeoff,
              color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TravelPlannerScreen())),
            ),
            _buildLifestyleCard(
              title: 'Guia Local',
              subtitle: 'Serviços',
              icon: Icons.map_outlined,
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServicesDirectoryScreen())),
            ),
            _buildLifestyleCard(
              title: 'Biometria',
              subtitle: 'Focinho Scan',
              icon: Icons.fingerprint,
              color: Colors.teal,
              onTap: () {
                if (_pets.length == 1) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => SnoutScannerScreen(
                        petId: _pets.first.id,
                        mode: ScannerMode.register,
                      )
                    )
                  );
                } else {
                  // Se tiver mais de um ou nenhum, abre busca
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SnoutScannerScreen(
                        mode: ScannerMode.search,
                      )
                    )
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLifestyleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSosDialog() {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um pet para usar o SOS')),
      );
      return;
    }

    final sosService = Provider.of<SosService>(context, listen: false);

    if (sosService.isSosActive) {
      sosService.deactivateSos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modo SOS desativado.'), backgroundColor: Colors.blue),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 ATIVAR MODO SOS?'),
        content: const Text('Isso enviará um alerta para TODOS os usuários num raio de 10km informando que seu pet acaba de fugir. Deseja prosseguir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await sosService.activateSos(
                petId: _pets.first.id,
                petName: _pets.first.name,
                lat: -23.5505,
                lng: -46.6333,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ALERTA SOS ENVIADO!'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ATIVAR SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontierFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🚀 Vanguarda Tecnológica'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFrontierCard(
                title: 'IA Comportamental',
                icon: Icons.psychology_outlined,
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BehavioralAnalysisScreen())),
              ),
              _buildFrontierCard(
                title: 'Rede Doadores',
                icon: Icons.favorite_border,
                color: Colors.red,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BloodDonorNetworkScreen())),
              ),
              _buildFrontierCard(
                title: 'IoT Hub Sync',
                icon: Icons.hub_outlined,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IotHubScreen())),
              ),
              _buildFrontierCard(
                title: 'Pet Trust',
                icon: Icons.security,
                color: const Color(0xFF1E293B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LegacyPlannerScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrontierCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPetsList() {
    if (_pets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.pets, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhum pet cadastrado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clique no + para adicionar seu primeiro pet!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _pets.map((pet) => _buildPetCard(pet)).toList(),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailScreen(petId: pet.id),
            ),
          ).then((_) => _loadData()),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'pet_avatar_${pet.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: pet.species == 'dog' ? Colors.amber.shade100 : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                      image: pet.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(pet.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pet.photoUrl == null
                        ? Icon(
                            Icons.pets,
                            color: pet.species == 'dog' ? Colors.amber.shade700 : Colors.purple.shade700,
                            size: 30,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            pet.speciesEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pet.breed ?? pet.speciesLabel,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ative as notificações',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Receba lembretes de vacinas e medicamentos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await NotificationService().initialize();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificações configuradas!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
  }

  void _navigateToVaccines() {
    if (_pets.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VaccinesScreen(petId: _pets.first.id),
        ),
      );
    }
  }

  Widget _buildAiAssistantCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AiChatScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: Colors.purple.shade700, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PetID AI Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dúvidas sobre o seu pet? Pergunte à nossa inteligência artificial!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color get shade600 => HSLColor.fromColor(this).withLightness(0.4).toColor();
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.3).toColor();
}
