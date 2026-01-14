import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String dose;

  @HiveField(2)
  final DateTime time;

  Medicine({required this.name, required this.dose, required this.time});
}
