import 'dart:io';
import 'package:dio/dio.dart';
import 'package:agriculture/features/diagnostic/data/models/diagnostic_model.dart'; // Need to create this model
import 'package:shared_preferences/shared_preferences.dart';

abstract class DiagnosticRemoteDataSource {
  Future<DiagnosticModel> analyzePlant(File image, {String? cropType, String? parcelleId});
  Future<List<DiagnosticModel>> getHistory();
}

class DiagnosticRemoteDataSourceImpl implements DiagnosticRemoteDataSource {
  final Dio dio;

  DiagnosticRemoteDataSourceImpl({required this.dio});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Future<DiagnosticModel> analyzePlant(File image, {String? cropType, String? parcelleId}) async {
    final token = await _getToken();
    try {
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path, filename: fileName),
        if (cropType != null) 'crop_type': cropType,
        if (parcelleId != null) 'parcelle_id': parcelleId,
      });

      final response = await dio.post(
        '/diagnostics/analyze',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        }),
      );

      if (response.statusCode == 200) {
        return DiagnosticModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to analyze plant');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<List<DiagnosticModel>> getHistory() async {
    final token = await _getToken();
    try {
      final response = await dio.get(
        '/diagnostics/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => DiagnosticModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
