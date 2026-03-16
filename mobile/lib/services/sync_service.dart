import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'api_service.dart';

class SyncService extends ChangeNotifier {
  final CacheService _cache = CacheService();
  final ApiService _api = ApiService();
  
  bool _isSyncing = false;
  DateTime? _lastSync;
  String? _error;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;
  String? get error => _error;

  /// Inicia a sincronização dos dados locais com a nuvem
  Future<void> syncAll() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      // Simulação de delay de rede
      await Future.delayed(const Duration(seconds: 2));

      // 1. Enviar mudanças locais pendentes (ex: novos pets criados offline)
      // 2. Buscar atualizações da nuvem
      // 3. Atualizar cache local
      
      _lastSync = DateTime.now();
      
      if (kDebugMode) {
        print('Sincronização concluída com sucesso em: $_lastSync');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Erro na sincronização: $_error');
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Verifica se há necessidade de sincronização automática
  Future<void> checkAutoSync() async {
    // Lógica para sincronizar automaticamente se o tempo desde o último sync for > 1 hora
    if (_lastSync == null || 
        DateTime.now().difference(_lastSync!).inHours >= 1) {
      await syncAll();
    }
  }
}
