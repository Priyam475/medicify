import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medicify/bloc/medicines_bloc.dart';
import 'package:medicify/models/medicine.dart';
import 'package:medicify/services/notification_service.dart';
import 'package:medicify/ui/screens/home_screen.dart';

void main() async {
  // This is the correct, simplified initialization sequence.
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Database first.
  await Hive.initFlutter();
  Hive.registerAdapter(MedicineAdapter());

  // 2. Initialize Notification Service (lightweight part only).
  final notificationService = NotificationService();
  await notificationService.init();

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
        // The time-consuming setup for timezone and permissions
        // is now correctly handled inside the HomeScreen after the app starts.
        home: HomeScreen(notificationService: notificationService),
      ),
    );
  }
}