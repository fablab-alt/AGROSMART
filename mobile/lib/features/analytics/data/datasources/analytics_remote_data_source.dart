import '../../../../core/network/api_client.dart';
import '../models/analytics_data_model.dart';

abstract class AnalyticsRemoteDataSource {
  Future<AnalyticsDataModel> getStats();
}

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  final ApiClient client;

  AnalyticsRemoteDataSourceImpl({required this.client});

  @override
  Future<AnalyticsDataModel> getStats() async {
    try {
      final response = await client.get('/analytics/stats');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return AnalyticsDataModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to load analytics data');
      }
    } catch (e) {
      throw Exception('Failed to load analytics data: $e');
    }
  }
}
