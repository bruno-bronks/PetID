import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/lost_pet_service.dart';
import 'report_lost_pet_screen.dart';
import '../services/api_service.dart';

class LostPetsMapScreen extends StatefulWidget {
  const LostPetsMapScreen({super.key});

  @override
  State<LostPetsMapScreen> createState() => _LostPetsMapScreenState();
}

class _LostPetsMapScreenState extends State<LostPetsMapScreen> {
  final _lostPetService = LostPetService();
  final _apiService = ApiService();
  List<LostPetReport> _reports = [];
  List<LostPetReport> _historyReports = [];
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  String _filter = 'all'; // 'all', 'lost', 'found', 'history'
  double _radiusKm = 50;

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
      // Obtém localização atual
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      _currentPosition = await Geolocator.getCurrentPosition();

      // Busca reportes próximos (ativos)
      final reports = await _lostPetService.getNearby(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _radiusKm,
        reportType: (_filter == 'all' || _filter == 'history') ? null : _filter,
      );

      // Busca histórico (meus reportes resolvidos)
      List<LostPetReport> history = [];
      try {
        final myReports = await _lostPetService.getMyReports();
        history = myReports.where((r) => r.status == 'resolved').toList();
        // Ordena por data (mais recente primeiro)
        history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {}

      setState(() {
        _reports = reports;
        _historyReports = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets Perdidos'),
        actions: [
          PopupMenuButton<double>(
            icon: const Icon(Icons.radar),
            tooltip: 'Raio de busca',
            onSelected: (value) {
              setState(() => _radiusKm = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 5, child: Text('5 km')),
              const PopupMenuItem(value: 10, child: Text('10 km')),
              const PopupMenuItem(value: 25, child: Text('25 km')),
              const PopupMenuItem(value: 50, child: Text('50 km')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Perdidos', 'lost'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Encontrados', 'found'),
                  const SizedBox(width: 8),
                  _buildFilterChip('📜 Histórico', 'history'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'found',
            onPressed: () => _reportPet('found'),
            backgroundColor: Colors.green,
            child: const Icon(Icons.pets),
            tooltip: 'Encontrei um pet',
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'lost',
            onPressed: () => _reportPet('lost'),
            backgroundColor: Colors.red,
            icon: const Icon(Icons.warning),
            label: const Text('Perdi meu pet'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
        _loadData();
      },
      selectedColor: Colors.blue.shade100,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
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

    // Se for histórico, mostra os reportes resolvidos
    if (_filter == 'history') {
      return _buildHistoryList();
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhum pet perdido na região!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Raio de ${_radiusKm.toInt()} km',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_historyReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhum histórico ainda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Seus pets resgatados aparecerão aqui',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyReports.length,
        itemBuilder: (context, index) {
          final report = _historyReports[index];
          return _buildHistoryCard(report);
        },
      ),
    );
  }

  Widget _buildHistoryCard(LostPetReport report) {
    // Se foi um reporte de "lost", mostra como PERDIDO (vermelho)
    // Se foi um reporte de "found", mostra como RESGATADO (verde)
    final isLostReport = report.isLost;
    final color = isLostReport ? Colors.red : Colors.green;
    final label = isLostReport ? '🔴 PERDIDO' : '✅ RESGATADO';
    // Data: para perdido mostra event_date, para resgatado mostra created_at (aproximado do resgate)
    final displayDate = isLostReport ? report.eventDate : report.createdAt;
    final hasPhoto = report.petPhotoUrl != null && report.petPhotoUrl!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isLostReport ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Foto/Ícone
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.2),
              backgroundImage: hasPhoto ? NetworkImage(_apiService.getFullUrl(report.petPhotoUrl!)) : null,
              child: hasPhoto ? null : Icon(
                isLostReport ? Icons.search_off : Icons.check_circle,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            
            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${report.speciesLabel} • ${_formatDate(displayDate)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  if (report.city != null)
                    Text(
                      '📍 ${report.city}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(LostPetReport report) {
    final isLost = report.isLost;
    final color = isLost ? Colors.red : Colors.green;
    final hasPhoto = report.petPhotoUrl != null && report.petPhotoUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto/Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                backgroundImage: hasPhoto ? NetworkImage(_apiService.getFullUrl(report.petPhotoUrl!)) : null,
                child: hasPhoto ? null : Icon(
                  isLost ? Icons.search : Icons.pets,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              
              // Informações
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isLost ? 'PERDIDO' : 'ENCONTRADO',
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (report.distanceKm != null)
                          Text(
                            report.distanceText,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${report.speciesLabel}${report.petBreed != null || report.foundBreed != null ? ' - ${report.petBreed ?? report.foundBreed}' : ''}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (report.address != null || report.city != null)
                      Text(
                        '📍 ${report.address ?? report.city}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Seta
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(LostPetReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Cabeçalho
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: (report.isLost ? Colors.red : Colors.green).withOpacity(0.2),
                    backgroundImage: report.petPhotoUrl != null ? NetworkImage(_apiService.getFullUrl(report.petPhotoUrl!)) : null,
                    child: report.petPhotoUrl == null ? Icon(
                      report.isLost ? Icons.search : Icons.pets,
                      size: 40,
                      color: report.isLost ? Colors.red : Colors.green,
                    ) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(report.speciesLabel),
                        if (report.distanceKm != null)
                          Text(
                            'A ${report.distanceText} de você',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Detalhes
              if (report.description != null) ...[
                const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(report.description!),
                const SizedBox(height: 16),
              ],
              
              _buildDetailRow(Icons.calendar_today, 'Data', _formatDate(report.eventDate)),
              if (report.address != null)
                _buildDetailRow(Icons.location_on, 'Local', report.address!),
              if (report.city != null)
                _buildDetailRow(Icons.location_city, 'Cidade', report.city!),
              
              const SizedBox(height: 24),
              
              // Contato
              if (report.contactPhone != null && report.contactVisible)
                ElevatedButton.icon(
                  onPressed: () => _launchPhone(report.contactPhone!),
                  icon: const Icon(Icons.phone),
                  label: Text('Ligar: ${report.contactPhone}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Botões de compartilhar
              if (report.isLost) ...[
                const Text('Compartilhar alerta:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareOnWhatsApp(report),
                        icon: const Icon(Icons.chat, color: Colors.green),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyShareText(report),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Botão "Confirmar Resgate"
              ElevatedButton.icon(
                onPressed: () => _markAsFound(report),
                icon: const Icon(Icons.celebration),
                label: Text(report.isLost ? 'Confirmar Resgate' : 'Marcar como Devolvido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _reportPet(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportLostPetScreen(
          reportType: type,
          currentPosition: _currentPosition,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getShareText(LostPetReport report) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 PET PERDIDO! 🚨');
    buffer.writeln();
    buffer.writeln('🐕 Nome: ${report.displayName}');
    buffer.writeln('📍 Raça: ${report.petBreed ?? "Não informada"}');
    if (report.description != null) {
      buffer.writeln('📝 Descrição: ${report.description}');
    }
    buffer.writeln('📅 Perdido em: ${_formatDate(report.eventDate)}');
    if (report.city != null) {
      buffer.writeln('🏙️ Cidade: ${report.city}');
    }
    if (report.address != null) {
      buffer.writeln('📍 Local: ${report.address}');
    }
    if (report.contactPhone != null && report.contactVisible) {
      buffer.writeln();
      buffer.writeln('📞 Contato: ${report.contactPhone}');
    }
    buffer.writeln();
    buffer.writeln('Se você viu esse pet, por favor entre em contato! 🙏');
    buffer.writeln();
    buffer.writeln('Enviado via PetID App');
    return buffer.toString();
  }

  Future<void> _shareOnWhatsApp(LostPetReport report) async {
    final text = Uri.encodeComponent(_getShareText(report));
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyShareText(LostPetReport report) {
    final text = _getShareText(report);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado! Cole onde quiser compartilhar.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _markAsFound(LostPetReport report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Que ótima notícia!'),
        content: Text('Confirma que encontrou ${report.displayName}?\n\nO reporte será removido da lista de pets perdidos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sim, encontrei!'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _lostPetService.resolveReport(report.id);
        if (!mounted) return;
        
        // Fecha o modal
        Navigator.pop(context);
        
        // Recarrega a lista
        _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 ${report.displayName} foi marcado como encontrado!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: Apenas o dono pode marcar como encontrado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
