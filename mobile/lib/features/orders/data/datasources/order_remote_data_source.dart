import 'package:agriculture/core/network/api_client.dart';
import 'package:agriculture/features/orders/data/models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getMyOrders();
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient client;

  OrderRemoteDataSourceImpl({required this.client});

  @override
  Future<List<OrderModel>> getMyOrders() async {
    try {
      // Endpoint likely needs to be verified. Assuming /marketplace/commandes/mes-achats or similar based on previous patterns.
      // But preserving existing path if verified: /marketplace/commandes?type=achats
      final response = await client.get(
        '/marketplace/commandes', 
        queryParameters: {'type': 'achats'},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
             final List<dynamic> list = data['data'];
             return list.map((json) => OrderModel.fromJson(json)).toList();
        } else {
             // Fallback if data is direct array or success flag missing
             if (data['data'] is List) {
                return (data['data'] as List).map((json) => OrderModel.fromJson(json)).toList();
             }
             return [];
        }
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }
}
