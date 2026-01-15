import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medicify/bloc/medicines_bloc.dart';
import 'package:medicify/models/medicine.dart';
import 'package:medicify/services/notification_service.dart';
import 'package:medicify/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize the database.
  await Hive.initFlutter();
  Hive.registerAdapter(MedicineAdapter());

  // 2. Initialize the notification service (lightweight part).
  final notificationService = NotificationService();
  notificationService.init(); // This is now a non-blocking call.

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MedicinesBloc(notificationService)..add(LoadMedicines()),
      child: MaterialApp(
        title: 'Medicify',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(notificationService: notificationService),
      ),
    );
  }
}
