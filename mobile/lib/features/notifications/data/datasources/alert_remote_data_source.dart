import 'package:dio/dio.dart';
import 'package:agriculture/features/notifications/data/models/alert_model.dart';

abstract class AlertRemoteDataSource {
  Future<List<AlertModel>> getAlerts();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class AlertRemoteDataSourceImpl implements AlertRemoteDataSource {
  final Dio dio;

  AlertRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await dio.get('/alertes'); // Ensure this endpoint exists in backend
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']; 
        return data.map((json) => AlertModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
     try {
      await dio.patch('/alertes/$id/read');
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead() async {
     try {
      await dio.post('/alertes/mark-all-read');
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }
}
