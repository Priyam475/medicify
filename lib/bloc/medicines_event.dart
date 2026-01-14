part of 'medicines_bloc.dart';

abstract class MedicinesEvent {}

class LoadMedicines extends MedicinesEvent {}

class AddMedicine extends MedicinesEvent {
  final Medicine medicine;

  AddMedicine(this.medicine);
}

class DeleteMedicine extends MedicinesEvent {
  final Medicine medicine;

  DeleteMedicine(this.medicine);
}
