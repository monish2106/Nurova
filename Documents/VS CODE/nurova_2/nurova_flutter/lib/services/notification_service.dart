import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> showRiskAlert(double riskProbability) async {
    final title = riskProbability > 0.75 ? '🚨 High Distraction Risk!' : '⚠️ Stay Focused';
    final body = riskProbability > 0.75
        ? 'Your risk is ${(riskProbability * 100).round()}%. Time to take a break.'
        : 'Risk at ${(riskProbability * 100).round()}%. Stay intentional with your time.';

    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nurova_risk',
          'Risk Alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF6C63FF),
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showNudge(String message) async {
    await _plugin.show(
      1,
      '💡 Nurova Nudge',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nurova_nudge',
          'Productivity Nudges',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

// ignore: non_constant_identifier_names
const Color = Object();
