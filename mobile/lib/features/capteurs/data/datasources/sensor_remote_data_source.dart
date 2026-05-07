import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:agriculture/features/capteurs/data/models/sensor_model.dart';

import 'package:agriculture/features/capteurs/domain/entities/sensor_measure.dart';

abstract class SensorRemoteDataSource {
  Future<List<SensorModel>> getSensors();
  Future<SensorModel> getSensorById(String id);
  Future<List<SensorMeasure>> getSensorHistory(String id);
  Future<void> toggleSensorStatus(String id, String status);
}

class SensorRemoteDataSourceImpl implements SensorRemoteDataSource {
  final Dio dio;

  SensorRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<SensorModel>> getSensors() async {
    debugPrint('[SENSORS_REMOTE] getSensors API call starting...');
    try {
      final response = await dio.get('/capteurs');
      debugPrint('[SENSORS_REMOTE] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['data']; // Adjust based on API structure
        debugPrint('[SENSORS_REMOTE] Got ${data.length} sensors from API');
        return data.map((json) => SensorModel.fromJson(json)).toList();
      } else {
        debugPrint('[SENSORS_REMOTE] Non-200 status: ${response.statusCode}');
        throw Exception('Failed to load sensors');
      }
    } catch (e) {
      debugPrint('[SENSORS_REMOTE] Error: $e');
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<SensorModel> getSensorById(String id) async {
    try {
      final response = await dio.get('/capteurs/$id');
      if (response.statusCode == 200) {
        return SensorModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load sensor');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<List<SensorMeasure>> getSensorHistory(String id) async {
    try {
      final response = await dio.get(
        '/capteurs/$id/mesures?limit=50&sort=desc',
      ); // Adjusted path slightly if needed, but Controller said /:id/mesures
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data
            .map(
              (json) => SensorMeasure(
                timestamp: DateTime.parse(json['timestamp']),
                value:
                    double.tryParse(json['valeur']?.toString() ?? '0') ?? 0.0,
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<void> toggleSensorStatus(String id, String status) async {
    debugPrint('[SENSORS_REMOTE] toggleSensorStatus: $id => $status');
    debugPrint('[SENSORS_REMOTE] Request body: ${{'status': status}}');
    try {
      final response = await dio.patch(
        '/capteurs/$id/toggle',
        data: {'status': status},
      );
      debugPrint('[SENSORS_REMOTE] Response status: ${response.statusCode}');
      debugPrint('[SENSORS_REMOTE] Response data: ${response.data}');
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to toggle sensor status: ${response.statusCode}',
        );
      }
      debugPrint('[SENSORS_REMOTE] Status toggled successfully');
    } on DioException catch (e) {
      debugPrint('[SENSORS_REMOTE] DioException caught!');
      debugPrint('[SENSORS_REMOTE] Status code: ${e.response?.statusCode}');
      debugPrint('[SENSORS_REMOTE] Response data: ${e.response?.data}');
      debugPrint('[SENSORS_REMOTE] Error message: ${e.message}');
      debugPrint('[SENSORS_REMOTE] Request data: ${e.requestOptions.data}');
      throw Exception('Network error: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('[SENSORS_REMOTE] Other error: $e');
      throw Exception('Network error: $e');
    }
  }
}
