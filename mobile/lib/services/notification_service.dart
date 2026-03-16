import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'api_service.dart';

/// Handler de mensagens em background (precisa ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensagem em background: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _api = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  // Canal de notificações Android
  static const AndroidNotificationChannel _vaccineChannel = AndroidNotificationChannel(
    'vaccine_reminders',
    'Lembretes de Vacina',
    description: 'Notificações de lembrete de vacinas',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _medicationChannel = AndroidNotificationChannel(
    'medication_reminders',
    'Lembretes de Medicamento',
    description: 'Notificações de lembrete de medicamentos',
    importance: Importance.high,
  );

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      await _initializeLocalNotifications();
      _initialized = true;
      print('NotificationService inicializado com sucesso.');
    } catch (e) {
      print('Erro ao inicializar NotificationService: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Cria canais Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_vaccineChannel);
      await androidPlugin.createNotificationChannel(_medicationChannel);
    }
  }

  Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('Permissão de notificação: ${settings.authorizationStatus}');
  }

  /// Obtém o token FCM para enviar notificações para este dispositivo
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    _fcmToken = await FirebaseMessaging.instance.getToken();
    return _fcmToken;
  }

  /// Registra o token no backend
  Future<void> registerToken(String token) async {
    try {
      await _api.post('/notifications/register', {
        'token': token,
        'platform': Platform.operatingSystem,
      });
      print('Token registrado no backend');
    } catch (e) {
      print('Erro ao registrar token: $e');
    }
  }

  /// Agenda lembrete de vacina
  Future<void> scheduleVaccineReminder({
    required int reminderId,
    required String petName,
    required String vaccineName,
    required DateTime scheduledDate,
    int daysBefore = 7,
  }) async {
    final notificationDate = scheduledDate.subtract(Duration(days: daysBefore));
    
    // Não agenda se a data já passou
    if (notificationDate.isBefore(DateTime.now())) {
      print('Data do lembrete já passou, não agendando');
      return;
    }
    
    try {
      await _localNotifications.zonedSchedule(
        id: reminderId,
        title: '💉 Lembrete de Vacina',
        body: '$petName precisa tomar a vacina $vaccineName em $daysBefore dias!',
        scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _vaccineChannel.id,
            _vaccineChannel.name,
            channelDescription: _vaccineChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      
      print('Lembrete de vacina agendado para $notificationDate');
    } catch (e) {
      print('Erro ao agendar lembrete de vacina: $e');
      // Tenta agendar sem ser exato se falhar (fallback)
       try {
        await _localNotifications.zonedSchedule(
        id: reminderId,
        title: '💉 Lembrete de Vacina',
        body: '$petName precisa tomar a vacina $vaccineName em $daysBefore dias!',
        scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
        notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _vaccineChannel.id,
              _vaccineChannel.name,
              channelDescription: _vaccineChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
             iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        print('Lembrete de vacina agendado (inexato) para $notificationDate');
      } catch (e2) {
        print('Falha fatal ao agendar vacina: $e2');
      }
    }
  }

  /// Agenda lembrete de medicamento
  Future<void> scheduleMedicationReminder({
    required int medicationId,
    required String petName,
    required String medicationName,
    required String time, // formato "HH:mm"
    bool daily = true,
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // Se o horário já passou hoje, agenda para amanhã
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    try {
      await _localNotifications.zonedSchedule(
        id: medicationId + 100000, // Offset para não conflitar com IDs de vacina
        title: '💊 Hora do Medicamento',
        body: '$petName precisa tomar $medicationName',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _medicationChannel.id,
            _medicationChannel.name,
            channelDescription: _medicationChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: daily ? DateTimeComponents.time : DateTimeComponents.dateAndTime,
      );
      
      print('Lembrete de medicamento agendado para $time');
    } catch (e) {
      print('Erro ao agendar lembrete de medicamento: $e');
      // Fallback para inexato
       try {
        await _localNotifications.zonedSchedule(
        id: medicationId + 100000,
        title: '💊 Hora do Medicamento',
        body: '$petName precisa tomar $medicationName',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _medicationChannel.id,
              _medicationChannel.name,
              channelDescription: _medicationChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: daily ? DateTimeComponents.time : DateTimeComponents.dateAndTime,
        );
        print('Lembrete de medicamento agendado (inexato) para $time');
      } catch (e2) {
        print('Falha fatal ao agendar medicamento: $e2');
      }
    }
  }

  /// Mostra notificação imediatamente
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _vaccineChannel.id,
          _vaccineChannel.name,
          channelDescription: _vaccineChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Cancela um lembrete específico
  Future<void> cancelReminder(int id) async {
    await _localNotifications.cancel(id: id);
    print('Lembrete $id cancelado');
  }

  /// Cancela todos os lembretes
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    print('Todos os lembretes cancelados');
  }

  /// Lista notificações pendentes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Handlers de mensagens
  void _handleForegroundMessage(RemoteMessage message) {
    print('Mensagem recebida em foreground: ${message.notification?.title}');
    
    // Mostra notificação local quando app está aberto
    if (message.notification != null) {
      showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'PetID',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App aberto via notificação: ${message.data}');
  }
}

@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse response) {
  print('Notificação tocada: ${response.payload}');
}

/// Widget para exibir status das notificações
class NotificationStatusWidget extends StatefulWidget {
  const NotificationStatusWidget({super.key});

  @override
  State<NotificationStatusWidget> createState() => _NotificationStatusWidgetState();
}

class _NotificationStatusWidgetState extends State<NotificationStatusWidget> {
  bool _notificationsEnabled = false;
  bool _loading = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final service = NotificationService();
      final token = await service.getToken();
      final pending = await service.getPendingNotifications();
      
      setState(() {
        _notificationsEnabled = token != null;
        _pendingCount = pending.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _notificationsEnabled = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        leading: CircularProgressIndicator(),
        title: Text('Verificando notificações...'),
      );
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(
            _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: _notificationsEnabled ? Colors.green : Colors.grey,
          ),
          title: const Text('Notificações Push'),
          subtitle: Text(_notificationsEnabled 
              ? 'Ativas - $_pendingCount lembretes agendados' 
              : 'Configure o Firebase para ativar'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: _notificationsEnabled ? (value) async {
              if (!value) {
                await NotificationService().cancelAllReminders();
                _checkNotificationStatus();
              }
            } : null,
          ),
        ),
        if (_notificationsEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Testa notificação
                await NotificationService().showNotification(
                  id: DateTime.now().millisecondsSinceEpoch,
                  title: '🐾 Teste PetID',
                  body: 'As notificações estão funcionando!',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificação de teste enviada!')),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Testar Notificação'),
            ),
          ),
      ],
    );
  }
}
