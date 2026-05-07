import 'package:isar/isar.dart';

part 'cached_sensor_data.g.dart';

@collection
class CachedSensorData {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sensorId;

  late String code;
  late String nom;
  late String type;
  late String status;
  String? parcelleNom;
  late double niveauBatterie;
  late String signalForce;
  late DateTime lastUpdate;

  double? lastValue;
  String? unit;
  double? nitrogen;
  double? phosphorus;
  double? potassium;
}
