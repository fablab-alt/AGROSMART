import 'package:isar/isar.dart';
import '../models/cached_sensor_data.dart';
import '../../domain/entities/sensor.dart';

abstract class SensorLocalDataSource {
  Future<List<Sensor>> getLastSensors();
  Future<void> cacheSensors(List<Sensor> sensors);
}

class SensorLocalDataSourceImpl implements SensorLocalDataSource {
  final Isar isar;

  SensorLocalDataSourceImpl({required this.isar});

  @override
  Future<List<Sensor>> getLastSensors() async {
    final cached = await isar.collection<CachedSensorData>().where().findAll();
    return cached
        .map(
          (c) => Sensor(
            id: c.sensorId,
            code: c.code,
            nom: c.nom,
            type: c.type,
            status: c.status,
            parcelleNom: c.parcelleNom,
            niveauBatterie: c.niveauBatterie,
            signalForce: c.signalForce,
            lastUpdate: c.lastUpdate,
            lastValue: c.lastValue,
            unit: c.unit,
            nitrogen: c.nitrogen,
            phosphorus: c.phosphorus,
            potassium: c.potassium,
          ),
        )
        .toList();
  }

  @override
  Future<void> cacheSensors(List<Sensor> sensors) async {
    final cachedList = sensors
        .map(
          (s) => CachedSensorData()
            ..sensorId = s.id
            ..code = s.code
            ..nom = s.nom
            ..type = s.type
            ..status = s.status
            ..parcelleNom = s.parcelleNom
            ..niveauBatterie = s.niveauBatterie
            ..signalForce = s.signalForce
            ..lastUpdate = s.lastUpdate
            ..lastValue = s.lastValue
            ..unit = s.unit
            ..nitrogen = s.nitrogen
            ..phosphorus = s.phosphorus
            ..potassium = s.potassium,
        )
        .toList();

    await isar.writeTxn(() async {
      // Clear old cache first, then insert fresh data
      await isar.collection<CachedSensorData>().clear();
      await isar.collection<CachedSensorData>().putAll(cachedList);
    });
  }
}
