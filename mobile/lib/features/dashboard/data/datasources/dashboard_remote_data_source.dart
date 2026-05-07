import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/dashboard_data_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSourceImpl({required this.dio});

  @override
  Future<DashboardDataModel> getDashboardData() async {
    try {
      final response = await dio.get('/dashboard/summary');
      
      if (response.statusCode == 200) {
        return DashboardDataModel.fromJson(response.data['data']);
      } else {
        throw ServerException('Erreur de chargement du tableau de bord');
      }
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? 'Erreur serveur');
    } catch (e) {
      throw ServerException('Erreur de connexion');
    }
  }
}
