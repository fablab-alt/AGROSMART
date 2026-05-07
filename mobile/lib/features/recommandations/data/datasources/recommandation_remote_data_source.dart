import 'package:dio/dio.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/recommandations/domain/entities/recommandation.dart';

class RecommandationRemoteDataSource {
  final ApiClient _apiClient;

  RecommandationRemoteDataSource(this._apiClient);

  /// Récupère les recommandations actives depuis l'API
  Future<List<Recommandation>> getActiveRecommandations() async {
    try {
      final response = await _apiClient.get('/recommandations/active');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => _fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  /// Récupère toutes les recommandations avec pagination
  Future<List<Recommandation>> getAllRecommandations({
    int page = 1,
    int limit = 20,
    String? type,
    String? priorite,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null) queryParams['type'] = type;
      if (priorite != null) queryParams['priorite'] = priorite;

      final response = await _apiClient.get(
        '/recommandations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => _fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  /// Récupère les recommandations pour une parcelle spécifique
  Future<List<Recommandation>> getRecommandationsByParcelle(
    String parcelleId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/recommandations',
        queryParameters: {'parcelleId': parcelleId},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => _fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  /// Marque une recommandation comme appliquée
  Future<bool> markAsApplied(String recommandationId) async {
    try {
      final response = await _apiClient.put(
        '/recommandations/$recommandationId',
        data: {'statut': 'appliquee'},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Recommandation _fromJson(Map<String, dynamic> json) {
    // Mapper le type depuis l'API
    RecommandationType type;
    final apiType = (json['type'] as String?)?.toLowerCase() ?? '';
    switch (apiType) {
      case 'irrigation':
        type = RecommandationType.irrigation;
        break;
      case 'fertilisation':
        type = RecommandationType.fertilisation;
        break;
      case 'phytosanitaire':
      case 'traitement':
        type = RecommandationType.phytosanitaire;
        break;
      default:
        type = RecommandationType.culture;
    }

    return Recommandation(
      id: json['id'] ?? '',
      titre: json['titre'] ?? json['title'] ?? '',
      description: json['description'] ?? json['message'] ?? '',
      type: type,
      priorite: json['priorite'] ?? json['priority'] ?? 'moyenne',
      parcelleId: json['parcelleId'] ?? '',
      parcelleNom: json['parcelle']?['nom'] ?? json['parcelleNom'] ?? '',
      dateCreation:
          DateTime.tryParse(json['createdAt'] ?? json['dateCreation'] ?? '') ??
          DateTime.now(),
      details: _parseDetails(json),
    );
  }

  Map<String, String> _parseDetails(Map<String, dynamic> json) {
    final details = <String, String>{};

    if (json['details'] != null && json['details'] is Map) {
      (json['details'] as Map).forEach((key, value) {
        details[key.toString()] = value.toString();
      });
    }

    // Ajouter des détails supplémentaires si disponibles
    if (json['quantite'] != null)
      details['Quantité'] = json['quantite'].toString();
    if (json['produit'] != null)
      details['Produit'] = json['produit'].toString();
    if (json['methode'] != null)
      details['Méthode'] = json['methode'].toString();

    return details;
  }
}
