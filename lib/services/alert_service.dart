import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

enum ThreatType {
  info,
  warning,
  audio,
  visual,
}

class ThreatAlert {
  final ThreatType type;
  final String message;
  final int threatLevel;
  final List<String> hazards;
  final DateTime timestamp;

  ThreatAlert({
    required this.type,
    required this.message,
    this.threatLevel = 0,
    this.hazards = const [],
    required this.timestamp,
  });
}

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  Future<void> init() async {
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

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (!_isInitialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'lora_alerts',
      'LIORA Alerts',
      channelDescription: 'Notifications from LIORA',
      importance: importance,
      priority: priority,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  Future<void> showThreatAlert(ThreatAlert alert) async {
    String title;
    Importance importance;

    switch (alert.type) {
      case ThreatType.warning:
        title = '⚠️ Hazard Detected';
        importance = Importance.max;
        break;
      case ThreatType.audio:
        title = '🔊 Concerning Sound';
        importance = Importance.high;
        break;
      case ThreatType.visual:
        title = '👁️ Visual Alert';
        importance = Importance.high;
        break;
      case ThreatType.info:
      default:
        title = 'ℹ️ LIORA Info';
        importance = Importance.defaultImportance;
    }

    await showNotification(
      title: title,
      body: alert.message,
      id: alert.timestamp.millisecondsSinceEpoch ~/ 1000,
      importance: importance,
    );

    if (_vibrationEnabled) {
      await _triggerVibration(alert.threatLevel);
    }
  }

  Future<void> _triggerVibration(int intensity) async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        if (intensity >= 80) {
          await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
        } else if (intensity >= 60) {
          await Vibration.vibrate(pattern: [0, 300, 200, 300]);
        } else {
          await Vibration.vibrate(duration: 200);
        }
      }
    } catch (e) {
      // Vibration not available
    }
  }

  Future<void> showRecordingStarted() async {
    await showNotification(
      title: '🔴 Recording Started',
      body: 'LIORA has started recording for your safety',
      id: 999,
    );
  }

  Future<void> showRecordingStopped() async {
    await showNotification(
      title: '⏹️ Recording Stopped',
      body: 'Recording has been saved',
      id: 998,
    );
  }

  Future<void> showLioraResponse(String message) async {
    await showNotification(
      title: '💬 LIORA',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      id: 997,
      importance: Importance.low,
      priority: Priority.low,
    );
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
