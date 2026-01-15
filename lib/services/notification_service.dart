import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:medicify/models/medicine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification plugin. This is a lightweight, synchronous operation.
  void init() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // This is not awaited, as it should run in the background.
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Handles the heavy, asynchronous setup for timezones and permissions.
  /// This should be called after the app's UI is visible.
  Future<void> setup() async {
    await _configureTimezone();
    await _requestPermissions();
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    final String timeZoneName =
        (await FlutterTimezone.getLocalTimezone()) as String;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> _requestPermissions() async {
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

    // Use the database key for a reliable, unique ID.
    final id = medicine.key as int;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
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
    // Use the same database key to cancel the notification.
    final id = medicine.key as int;
    await flutterLocalNotificationsPlugin.cancel(id);
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
