part of 'medicines_bloc.dart';

abstract class MedicinesState {}

class MedicinesInitial extends MedicinesState {}

class MedicinesLoadInProgress extends MedicinesState {}

class MedicinesLoadSuccess extends MedicinesState {
  final List<Medicine> medicines;

  MedicinesLoadSuccess(this.medicines);
}

class MedicinesLoadFailure extends MedicinesState {}
