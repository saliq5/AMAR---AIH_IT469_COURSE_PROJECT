import "package:flutter_local_notifications/flutter_local_notifications.dart";
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';

class NotificationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FlutterLocalNotificationsPlugin _notification = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          navigatorKey.currentState?.pushNamed(payload);
        }
      },
    );

    tz.initializeTimeZones();
  }

  // New method to schedule a notification for a specific date and time
  static Future<void> scheduleNotificationAtDateTime({
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? routeName,
}) async {
  const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
    'medication_reminder',
    'Medication Reminder Channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  // Ensure the scheduled date is in the future
  final DateTime futureDate = scheduledDate.isAfter(DateTime.now()) 
    ? scheduledDate 
    : scheduledDate.add(Duration(days: 1));

  final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(futureDate, tz.local);

  await _notification.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch.remainder(100000), 
    title, 
    body, 
    tzScheduledDate,
    notificationDetails,
    payload: routeName,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

  // Method to cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notification.cancel(id);
  }

  // Method to cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notification.cancelAll();
  }
}