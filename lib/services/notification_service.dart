import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static int _notificationId = 0;

  static Future<bool> _requestPermissions() async {
    if (await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission() ??
        false) {
      return true;
    }

    final bool? iosPermission = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return iosPermission ?? false;
  }

  static int _getNextNotificationId() {
    _notificationId = (_notificationId + 1) % 2147483647;
    return _notificationId;
  }

  static Future<void> initialize() async {
    try {
      // Configurações de inicialização para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configurações de inicialização para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Vamos solicitar depois
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Configurações gerais de inicialização
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Aqui você pode adicionar lógica para quando o usuário toca na notificação
        },
      );

      // Solicita permissões após a inicialização
      await _requestPermissions();
    } catch (e) {
      print('Erro ao inicializar notificações: $e');
    }
  }

  static Future<void> showGameNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'game_notifications',
        'Notificações do Jogo',
        channelDescription: 'Canal para notificações do jogo',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _getNextNotificationId(),
        title,
        body,
        details,
      );
    } catch (e) {
      print('Erro ao mostrar notificação: $e');
    }
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required int delayInSeconds,
  }) async {
    try {
      // Para sistemas de notificação simples, vamos usar apenas notificações imediatas
      // ou implementar um timer para mostrar a notificação após o delay
      await Future.delayed(Duration(seconds: delayInSeconds > 10 ? 10 : delayInSeconds), () async {
        await showGameNotification(title: title, body: body);
      });
    } catch (e) {
      print('Erro ao agendar notificação: $e');
    }
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Erro ao cancelar notificações: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('Erro ao cancelar notificação específica: $e');
    }
  }
}