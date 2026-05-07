import 'package:dio/dio.dart';
import 'package:agriculture/features/formations/data/models/formation_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class FormationRemoteDataSource {
  Future<List<FormationModel>> getFormations();
}

class FormationRemoteDataSourceImpl implements FormationRemoteDataSource {
  final Dio dio;

  FormationRemoteDataSourceImpl({required this.dio});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<List<FormationModel>> getFormations() async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/formations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => FormationModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load formations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
