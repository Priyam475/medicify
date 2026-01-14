import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:medicify/models/medicine.dart';
import 'package:medicify/services/notification_service.dart';

part 'medicines_event.dart';
part 'medicines_state.dart';

class MedicinesBloc extends Bloc<MedicinesEvent, MedicinesState> {
  final NotificationService _notificationService;

  MedicinesBloc(this._notificationService) : super(MedicinesInitial()) {
    on<LoadMedicines>(_onLoadMedicines);
    on<AddMedicine>(_onAddMedicine);
    on<DeleteMedicine>(_onDeleteMedicine);
  }

  Future<void> _onLoadMedicines(
      LoadMedicines event, Emitter<MedicinesState> emit) async {
    emit(MedicinesLoadInProgress());
    try {
      final box = await Hive.openBox<Medicine>('medicines');
      final medicines = box.values.toList();
      medicines.sort((a, b) => a.time.compareTo(b.time));
      emit(MedicinesLoadSuccess(medicines));
    } catch (_) {
      emit(MedicinesLoadFailure());
    }
  }

  Future<void> _onAddMedicine(
      AddMedicine event, Emitter<MedicinesState> emit) async {
    final box = await Hive.openBox<Medicine>('medicines');
    final key = await box.add(event.medicine);
    final managedMedicine = box.get(key);

    if (managedMedicine != null) {
      await _notificationService.scheduleNotification(managedMedicine);
    }
  }

  Future<void> _onDeleteMedicine(
      DeleteMedicine event, Emitter<MedicinesState> emit) async {
    final currentState = state;
    if (currentState is MedicinesLoadSuccess) {
      await _notificationService.cancelNotification(event.medicine);
      await event.medicine.delete();

      final updatedList = currentState.medicines
          .where((m) => m.key != event.medicine.key)
          .toList();
      emit(MedicinesLoadSuccess(updatedList));
    }
  }
}
