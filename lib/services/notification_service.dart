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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
    String timeZoneName;
    try {
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      timeZoneName = result.toString();
    } catch (e) {
      timeZoneName = 'UTC';
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    // await requestPermissions(); // Moved to HomeScreen
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
    await flutterLocalNotificationsPlugin.zonedSchedule(
      medicine.hashCode,
      'Time for your medicine!',
      'Take your ${medicine.name} (${medicine.dose})',
      _nextInstanceOfTime(medicine.time),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  Future<void> cancelNotification(Medicine medicine) async {
    await flutterLocalNotificationsPlugin.cancel(medicine.hashCode);
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Create a generic DateTime for the target time today, using device local time context
    final DateTime deviceNow = DateTime.now();
    final DateTime targetDate = DateTime(
      deviceNow.year,
      deviceNow.month,
      deviceNow.day,
      time.hour,
      time.minute,
    );

    // Convert the local DateTime to the target timezone (tz.local), preserving absolute execution time
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(targetDate, tz.local);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
