import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const int _reminderId = 1001;

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Enables a daily reminder notification. Note: this fires roughly 24
  /// hours after being scheduled (not pinned to a specific clock time),
  /// which keeps the implementation simple and avoids timezone setup.
  static Future<void> enableDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Plant Care Reminder',
      channelDescription: 'Reminds you to check on your plants',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.periodicallyShow(
      _reminderId,
      'FloraShield AI 🌿',
      'Don\'t forget to check on your plants today!',
      RepeatInterval.daily,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Fires a single one-shot notification right away -- used for real-time
  /// alerts (e.g. "disease detected", "toxic plant identified"), as
  /// opposed to the recurring daily reminder above. Uses its own channel
  /// so users can mute/configure it separately from the daily reminder in
  /// their OS notification settings.
  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_alert_channel',
      'Scan Alerts',
      channelDescription: 'Real-time alerts from disease and toxicity scans',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, notificationDetails);
  }

  static Future<void> disableDailyReminder() async {
    await _plugin.cancel(_reminderId);
  }
}