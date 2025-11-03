import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermission() async {
    // Request notification permission
    final status = await Permission.notification.request();

    if (status.isGranted) {
      // For Android 13+, also request post notifications permission
      if (await Permission.notification.isDenied) {
        final postNotificationStatus = await Permission.notification.request();
        return postNotificationStatus.isGranted;
      }
      return true;
    }

    return false;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Napolill Erinnerung',
    String body = 'Zeit für deine tägliche Affirmation! 🌟',
  }) async {
    if (!await hasPermission()) {
      debugPrint('No notification permission');
      return;
    }

    try {
      // Cancel existing notifications
      await cancelAllNotifications();

      // Schedule daily notification
      await _notifications.zonedSchedule(
        0, // Unique ID
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'napolill_daily',
            'Napolill Daily Reminders',
            channelDescription: 'Tägliche Erinnerungen für Napolill',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('Daily reminder scheduled for $hour:$minute');
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        debugPrint('Exact alarms not permitted. User needs to enable it in system settings.');
        rethrow; // Rethrow so caller can handle it
      } else {
        debugPrint('Error scheduling notification: ${e.message}');
        rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error scheduling notification: $e');
      rethrow;
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Show immediate notification for testing
  Future<void> showTestNotification() async {
    if (!await hasPermission()) {
      debugPrint('No notification permission for test');
      return;
    }

    await _notifications.show(
      999, // Test notification ID
      'Napolill Test',
      'Benachrichtigungen funktionieren! 🎉',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'napolill_test',
          'Napolill Test',
          channelDescription: 'Test-Benachrichtigungen',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
