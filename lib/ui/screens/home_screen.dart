import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicify/bloc/medicines_bloc.dart';
import 'package:medicify/services/notification_service.dart';
import 'package:medicify/ui/screens/add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.notificationService});

  final NotificationService notificationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _configureApp();
    });
  }

  Future<void> _configureApp() async {
    await widget.notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicify'),
        backgroundColor: Colors.teal,
      ),
      body: BlocBuilder<MedicinesBloc, MedicinesState>(
        builder: (context, state) {
          if (state is MedicinesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicinesLoadFailure) {
            return const Center(child: Text('Failed to load medicines'));
          } else if (state is MedicinesLoadSuccess) {
            if (state.medicines.isEmpty) {
              return const Center(child: Text('No medicines added yet'));
            }
            return ListView.builder(
              itemCount: state.medicines.length,
              itemBuilder: (context, index) {
                final medicine = state.medicines[index];
                return ListTile(
                  title: Text(medicine.name),
                  subtitle: Text(
                      '${medicine.dose} - ${medicine.time.hour}:${medicine.time.minute}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.orange),
                    onPressed: () {
                      context
                          .read<MedicinesBloc>()
                          .add(DeleteMedicine(medicine));
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
          );

          if (result == true) {
            if (context.mounted) {
              context.read<MedicinesBloc>().add(LoadMedicines());
            }
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
