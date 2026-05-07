import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:agriculture/features/parcelles/data/models/parcelle_model.dart';
import 'package:agriculture/features/parcelles/data/models/iot_metric_model.dart';

abstract class ParcelleRemoteDataSource {
  Future<List<ParcelleModel>> getParcelles();
  Future<void> createParcelle(Map<String, dynamic> data);
  Future<IotMetricsResponse> getParcelleIotMetrics(String parcelleId);
}

class ParcelleRemoteDataSourceImpl implements ParcelleRemoteDataSource {
  final Dio dio;

  ParcelleRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ParcelleModel>> getParcelles() async {
    try {
      debugPrint('[PARCELLE DS] Fetching parcelles...');
      final response = await dio.get('/parcelles');
      debugPrint('[PARCELLE DS] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['data']; // Adjust based on API structure
        return data.map((json) => ParcelleModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load parcelles');
      }
    } catch (e) {
      debugPrint('[PARCELLE DS] Error getting parcelles: $e');
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<void> createParcelle(Map<String, dynamic> data) async {
    try {
      debugPrint('[PARCELLE DS] Creating parcelle with data: $data');
      final response = await dio.post('/parcelles', data: data);
      debugPrint('[PARCELLE DS] Create response: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('[PARCELLE DS] DioException: ${e.type} - ${e.message}');
      throw Exception(
        'Erreur réseau: ${e.response?.data?['message'] ?? e.message}',
      );
    } catch (e) {
      debugPrint('[PARCELLE DS] Exception: $e');
      throw Exception('Failed to create parcelle: $e');
    }
  }

  @override
  Future<IotMetricsResponse> getParcelleIotMetrics(String parcelleId) async {
    try {
      debugPrint(
        '[PARCELLE DS] Fetching IoT metrics for parcelle: $parcelleId',
      );
      final response = await dio.get('/parcelles/$parcelleId/iot-metrics');
      debugPrint('[PARCELLE DS] IoT metrics response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return IotMetricsResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load IoT metrics');
      }
    } on DioException catch (e) {
      debugPrint(
        '[PARCELLE DS] DioException getting IoT metrics: ${e.type} - ${e.message}',
      );
      // Retourner une réponse vide au lieu de lever une exception
      return const IotMetricsResponse(
        metrics: [],
        groupedByType: {},
        totalCapteurs: 0,
        capteursAvecDonnees: 0,
        message: 'Erreur de connexion au serveur',
      );
    } catch (e) {
      debugPrint('[PARCELLE DS] Error getting IoT metrics: $e');
      return const IotMetricsResponse(
        metrics: [],
        groupedByType: {},
        totalCapteurs: 0,
        capteursAvecDonnees: 0,
        message: 'Aucune donnée disponible',
      );
    }
  }
}
