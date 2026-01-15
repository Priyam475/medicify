import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medicify/models/medicine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
    await createNotificationChannel();
  }

  Future<void> configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).toString();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('Error setting local location: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Error getting local timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> requestPermissions() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> scheduleNotification(Medicine medicine) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'medicify_channel',
      'Medicify',
      channelDescription: 'Channel for medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    final scheduledDate = _nextInstanceOfTime(medicine.time);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        medicine.key as int,
        'Time for your medicine!',
        'Take your ${medicine.name} (${medicine.dose})',
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('ERROR SCHEDULING NOTIFICATION: $e');
    }
  }

  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medicify_channel', // id
      'Medicify', // title
      description: 'Channel for medicine reminders',
      importance: Importance.max,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> cancelNotification(Medicine medicine) async {
    await flutterLocalNotificationsPlugin.cancel(medicine.key as int);
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    // Current time in the configured local timezone
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Convert the incoming DateTime (which represents the target time on the current day)
    // to the configured local timezone, preserving the exact instant in time.
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(time, tz.local);

    // If the scheduled time is in the past, assume it's for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
