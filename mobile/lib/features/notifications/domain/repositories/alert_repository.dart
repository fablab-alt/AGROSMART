import 'package:agriculture/features/notifications/domain/entities/alert.dart';

abstract class AlertRepository {
  Future<List<Alert>> getAlerts();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
