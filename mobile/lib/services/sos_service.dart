import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'lost_pet_service.dart';

class SosService extends ChangeNotifier {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  final _lostPetService = LostPetService();
  final _notificationService = NotificationService();

  bool _isSosActive = false;
  bool get isSosActive => _isSosActive;

  /// Ativa o modo SOS para um pet específico
  Future<void> activateSos({
    required int petId,
    required String petName,
    required double lat,
    required double lng,
  }) async {
    _isSosActive = true;
    notifyListeners();

    try {
      // 1. Criar um alerta de pet perdido automaticamente
      await _lostPetService.reportLost(
        petId: petId,
        latitude: lat,
        longitude: lng,
        address: 'Última localização conhecida (SOS)',
        description: 'EMERGÊNCIA: Pet fugiu agora!',
        eventDate: DateTime.now(),
      );

      // 2. Notificar usuários próximos (Simulação)
      await _notificationService.showNotification(
        id: 999,
        title: '🚨 ALERTA SOS: $petName Perdido!',
        body: 'Um pet acaba de fugir nas proximidades. Fique atento!',
      );

      if (kDebugMode) {
        print('Modo SOS ativado para o pet: $petName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao ativar SOS: $e');
      }
      rethrow;
    }
  }

  /// Desativa o modo SOS
  void deactivateSos() {
    _isSosActive = false;
    notifyListeners();
  }
}
