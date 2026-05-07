import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';

abstract class SensorRepository {
  Future<List<Sensor>> getSensors();
  Future<Sensor> getSensorById(String id);
  Future<List<SensorMeasure>> getSensorHistory(String id);
  Future<void> toggleSensorStatus(String id, String status);
}
