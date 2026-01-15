import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicify/bloc/medicines_bloc.dart';
import 'package:medicify/models/medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  TimeOfDay? _time;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a medicine name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _doseController,
                decoration: const InputDecoration(labelText: 'Dose'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a dose';
                  }
                  return null;
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_time == null ? 'Select time' : _time!.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() {
                      _time = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_time == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a time')),
                    );
                    return;
                  }
                  if (_formKey.currentState!.validate()) {
                    final now = DateTime.now();
                    final time = DateTime(now.year, now.month, now.day, _time!.hour, _time!.minute);
                    final medicine = Medicine(
                      name: _nameController.text,
                      dose: _doseController.text,
                      time: time,
                    );
                    context.read<MedicinesBloc>().add(AddMedicine(medicine));
                    Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
