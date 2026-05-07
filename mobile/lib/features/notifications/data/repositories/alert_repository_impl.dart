import 'package:agriculture/features/notifications/data/datasources/alert_remote_data_source.dart';
import 'package:agriculture/features/notifications/domain/entities/alert.dart';
import 'package:agriculture/features/notifications/domain/repositories/alert_repository.dart';

class AlertRepositoryImpl implements AlertRepository {
  final AlertRemoteDataSource remoteDataSource;

  AlertRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Alert>> getAlerts() async {
    return await remoteDataSource.getAlerts();
  }

  @override
  Future<void> markAsRead(String id) async {
    await remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await remoteDataSource.markAllAsRead();
  }
}
