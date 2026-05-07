import '../../../../core/network/api_client.dart';
import '../models/activite_model.dart';
import '../../domain/entities/activite.dart';

class CalendrierRemoteDataSource {
  final ApiClient apiClient;

  CalendrierRemoteDataSource(this.apiClient);

  Future<List<ActiviteModel>> getActivites({
    String? parcelleId,
    TypeActivite? typeActivite,
    StatutActivite? statut,
    PrioriteActivite? priorite,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (parcelleId != null) queryParams['parcelleId'] = parcelleId;
    if (typeActivite != null)
      queryParams['typeActivite'] = typeActivite.apiValue;
    if (statut != null) queryParams['statut'] = statut.apiValue;
    if (priorite != null) queryParams['priorite'] = priorite.apiValue;
    if (dateDebut != null)
      queryParams['dateDebut'] = dateDebut.toIso8601String();
    if (dateFin != null) queryParams['dateFin'] = dateFin.toIso8601String();

    final response = await apiClient.get(
      '/calendrier',
      queryParameters: queryParams,
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => ActiviteModel.fromJson(json)).toList();
  }

  Future<ActiviteModel> getActiviteById(String id) async {
    final response = await apiClient.get('/calendrier/$id');
    return ActiviteModel.fromJson(response.data['data']);
  }

  Future<ActiviteModel> createActivite(Map<String, dynamic> data) async {
    final response = await apiClient.post('/calendrier', data: data);
    return ActiviteModel.fromJson(response.data['data']);
  }

  Future<ActiviteModel> updateActivite(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await apiClient.put('/calendrier/$id', data: data);
    return ActiviteModel.fromJson(response.data['data']);
  }

  Future<void> deleteActivite(String id) async {
    await apiClient.delete('/calendrier/$id');
  }

  Future<List<ActiviteModel>> getActivitesProchaines(int jours) async {
    final response = await apiClient.get(
      '/calendrier/prochaines',
      queryParameters: {'jours': jours.toString()},
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => ActiviteModel.fromJson(json)).toList();
  }

  Future<ActiviteModel> marquerTerminee(String id) async {
    final response = await apiClient.patch('/calendrier/$id/terminer');
    return ActiviteModel.fromJson(response.data['data']);
  }
}
