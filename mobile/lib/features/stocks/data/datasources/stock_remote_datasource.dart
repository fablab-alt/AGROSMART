import '../../../../core/network/api_client.dart';
import '../models/stock_model.dart';

/// Source de données distante pour les stocks
class StockRemoteDataSource {
  final ApiClient apiClient;

  StockRemoteDataSource({required this.apiClient});

  /// Récupère la liste des stocks
  Future<List<StockModel>> getStocks({
    String? categorie,
    String? parcelleId,
    bool? estActif,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (categorie != null) queryParameters['categorie'] = categorie;
      if (parcelleId != null) queryParameters['parcelleId'] = parcelleId;
      if (estActif != null) queryParameters['estActif'] = estActif.toString();

      final response = await apiClient.get(
        '/stocks',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final data = response.data['data'] as List;
      return data
          .map((json) => StockModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des stocks: $e');
    }
  }

  /// Récupère un stock par son ID
  Future<StockModel> getStockById(String id) async {
    try {
      final response = await apiClient.get('/stocks/$id');
      return StockModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du stock: $e');
    }
  }

  /// Crée un nouveau stock
  Future<StockModel> createStock(Map<String, dynamic> stockData) async {
    try {
      final response = await apiClient.post('/stocks', data: stockData);
      return StockModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la création du stock: $e');
    }
  }

  /// Met à jour un stock
  Future<StockModel> updateStock(
    String id,
    Map<String, dynamic> stockData,
  ) async {
    try {
      final response = await apiClient.put('/stocks/$id', data: stockData);
      return StockModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du stock: $e');
    }
  }

  /// Supprime un stock (soft delete)
  Future<void> deleteStock(String id) async {
    try {
      await apiClient.delete('/stocks/$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression du stock: $e');
    }
  }

  /// Ajoute un mouvement de stock
  Future<Map<String, dynamic>> addMouvement(
    String stockId,
    Map<String, dynamic> mouvementData,
  ) async {
    try {
      final response = await apiClient.post(
        '/stocks/$stockId/mouvement',
        data: mouvementData,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout du mouvement: $e');
    }
  }

  /// Récupère les alertes d'un stock
  Future<List<AlerteStockModel>> getAlertes(String stockId) async {
    try {
      final response = await apiClient.get('/stocks/$stockId/alertes');
      final data = response.data['data'] as List;
      return data
          .map(
            (json) => AlerteStockModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des alertes: $e');
    }
  }

  /// Marque une alerte comme lue
  Future<AlerteStockModel> marquerAlerteLue(
    String stockId,
    String alerteId,
  ) async {
    try {
      final response = await apiClient.patch(
        '/stocks/$stockId/alertes/$alerteId/marquer-lue',
      );
      return AlerteStockModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Erreur lors du marquage de l\'alerte: $e');
    }
  }

  /// Récupère les statistiques des stocks
  Future<Map<String, dynamic>> getStatistiques() async {
    try {
      final response = await apiClient.get('/stocks/statistiques');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
