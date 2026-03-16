import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/vaccine_service.dart';
import '../services/sync_service.dart';
import 'dashboard_screen.dart';
import 'pets_list_screen.dart';
import 'add_pet_screen.dart';
import 'snout_scanner_screen.dart';
import 'vaccines_screen.dart';
import 'lost_pets_map_screen.dart';
import 'ai_chat_screen.dart';
import 'services_directory_screen.dart';
import 'privacy_center_screen.dart';
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _petsListKey = GlobalKey<PetsListScreenState>();
  final _vaccineService = VaccineService();
  UpcomingVaccines? _upcomingVaccines;

  @override
  void initState() {
    super.initState();
    _loadVaccineNotifications();
  }

  Future<void> _loadVaccineNotifications() async {
    try {
      final upcoming = await _vaccineService.getUpcomingVaccines(daysAhead: 30);
      if (!mounted) return;
      setState(() => _upcomingVaccines = upcoming);
    } catch (e) {
      // Ignorar erros de vacinas
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final syncService = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          // Badge de vacinas atrasadas
          if (_upcomingVaccines != null && _upcomingVaccines!.hasOverdue)
            IconButton(
              icon: Badge(
                label: Text(_upcomingVaccines!.overdue.length.toString()),
                backgroundColor: Colors.red,
                child: const Icon(Icons.vaccines),
              ),
              onPressed: () => setState(() => _currentIndex = 2),
              tooltip: 'Vacinas atrasadas!',
            ),
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(
                      syncService.isSyncing ? Icons.sync : Icons.cloud_upload_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(syncService.isSyncing ? 'Sincronizando...' : 'Sincronizar Dados'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'privacy',
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    const Text('Centro de Privacidade'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'tutorial',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    const Text('Tutorial PetID'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await authService.logout();
              } else if (value == 'sync') {
                if (!syncService.isSyncing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Iniciando sincronização...')),
                  );
                  await syncService.syncAll();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(syncService.error ?? 'Sincronização concluída!'),
                        backgroundColor: syncService.error != null ? Colors.red : Colors.green,
                      ),
                    );
                  }
                }
              } else if (value == 'privacy') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyCenterScreen()));
              } else if (value == 'tutorial') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'PetID';
      case 1:
        return 'Serviços';
      case 2:
        return 'Vacinas';
      case 3:
        return 'Buscar Pet';
      case 4:
        return 'PetID AI';
      default:
        return 'PetID';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ServicesDirectoryScreen();
      case 2:
        return _buildVaccinesOverview();
      case 3:
        return _buildSearchScreen();
      case 4:
        return const AiChatScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildSearchScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                size: 64,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Encontrou um Pet Perdido?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Escaneie o focinho do pet para tentar encontrar o dono.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SnoutScannerScreen(
                      mode: ScannerMode.search,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Escanear Focinho'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Como funciona?',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O focinho de cada pet é único, como uma impressão digital. '
                    'Ao escanear, comparamos com nossa base de dados para '
                    'encontrar o dono do pet.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinesOverview() {
    return FutureBuilder<UpcomingVaccines>(
      future: _vaccineService.getUpcomingVaccines(daysAhead: 30),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.totalPending == 0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tudo em dia!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não há vacinas pendentes nos próximos 30 dias',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Resumo
              Row(
                children: [
                  _buildSummaryCard(
                    'Atrasadas',
                    data.overdue.length,
                    Colors.red,
                    Icons.warning,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Próximas',
                    data.upcoming.length,
                    Colors.orange,
                    Icons.schedule,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Vacinas atrasadas
              if (data.overdue.isNotEmpty) ...[
                _buildSectionTitle('⚠️ Vacinas Atrasadas', Colors.red),
                ...data.overdue.map((v) => _buildVaccineCard(v, isOverdue: true)),
                const SizedBox(height: 16),
              ],

              // Vacinas próximas
              if (data.upcoming.isNotEmpty) ...[
                _buildSectionTitle('📅 Próximas Vacinas', Colors.orange),
                ...data.upcoming.map((v) => _buildVaccineCard(v)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVaccineCard(VaccineReminder vaccine, {bool isOverdue = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue 
              ? Colors.red.shade100 
              : Colors.orange.shade100,
          child: Icon(
            Icons.vaccines,
            color: isOverdue ? Colors.red : Colors.orange,
          ),
        ),
        title: Text(
          vaccine.vaccineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDate(vaccine.scheduledDate)} - ${vaccine.statusText}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão para marcar como tomada
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              color: Colors.green,
              tooltip: 'Marcar como tomada',
              onPressed: () => _markVaccineAsCompleted(vaccine),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VaccinesScreen(petId: vaccine.petId),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markVaccineAsCompleted(VaccineReminder vaccine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Marcar "${vaccine.vaccineName}" como tomada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _vaccineService.completeReminder(vaccine.id, completedDate: DateTime.now());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vaccine.vaccineName} marcada como tomada!'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarrega a lista
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Widget? _buildFAB() {
    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
          if (result == true) {
            _petsListKey.currentState?.refresh();
          }
        },
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        if (index == 2) {
          _loadVaccineNotifications();
        }
      },
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Início',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Serviços',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: _upcomingVaccines?.hasOverdue ?? false,
            label: Text(_upcomingVaccines?.overdue.length.toString() ?? ''),
            child: const Icon(Icons.vaccines),
          ),
          label: 'Vacinas',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Buscar',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'AI Chat',
        ),
      ],
    );
  }
}
