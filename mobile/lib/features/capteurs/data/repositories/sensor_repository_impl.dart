import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../datasources/sensor_local_data_source.dart';
import 'package:agriculture/features/capteurs/data/datasources/sensor_remote_data_source.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor.dart';
import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';
import 'package:agriculture/features/capteurs/domain/repositories/sensor_repository.dart';

class SensorRepositoryImpl implements SensorRepository {
  final SensorRemoteDataSource remoteDataSource;
  final SensorLocalDataSource localDataSource;
  final InternetConnection networkInfo;

  SensorRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<List<Sensor>> getSensors() async {
    debugPrint('[SENSORS] getSensors called');

    // Tenter d'abord la requête remote - la vérification réseau peut être peu fiable sur émulateur
    try {
      final sensors = await remoteDataSource.getSensors();
      debugPrint('[SENSORS] Got ${sensors.length} sensors from remote');
      await localDataSource.cacheSensors(sensors);
      return sensors;
    } catch (e) {
      debugPrint('[SENSORS] Remote error: $e - trying local cache');
      // En cas d'erreur, essayer le cache local
      try {
        final cachedSensors = await localDataSource.getLastSensors();
        if (cachedSensors.isNotEmpty) {
          debugPrint(
            '[SENSORS] Got ${cachedSensors.length} sensors from cache',
          );
          return cachedSensors;
        }
      } catch (cacheError) {
        debugPrint('[SENSORS] Cache error: $cacheError');
      }
      // Si tout échoue, retourner liste vide
      debugPrint('[SENSORS] No sensors available');
      return [];
    }
  }

  @override
  Future<Sensor> getSensorById(String id) async {
    debugPrint('[SENSORS] getSensorById called: $id');
    try {
      return await remoteDataSource.getSensorById(id);
    } catch (e) {
      debugPrint('[SENSORS] Remote error for sensor $id: $e - trying local');
      // Fallback: chercher dans le cache local
      final sensors = await localDataSource.getLastSensors();
      return sensors.firstWhere((s) => s.id == id);
    }
  }

  @override
  Future<List<SensorMeasure>> getSensorHistory(String id) async {
    debugPrint('[SENSORS] getSensorHistory called: $id');
    try {
      return await remoteDataSource.getSensorHistory(id);
    } catch (e) {
      debugPrint('[SENSORS] History error: $e');
      return []; // Return empty if error
    }
  }

  @override
  Future<void> toggleSensorStatus(String id, String status) async {
    debugPrint('[SENSORS] toggleSensorStatus called: $id => $status');
    try {
      await remoteDataSource.toggleSensorStatus(id, status);
      debugPrint('[SENSORS] Status toggled successfully');
    } catch (e) {
      debugPrint('[SENSORS] Toggle error: $e');
      throw Exception('Failed to toggle sensor status: $e');
    }
  }
}
