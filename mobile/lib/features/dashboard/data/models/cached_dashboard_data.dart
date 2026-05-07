import 'package:isar/isar.dart';

part 'cached_dashboard_data.g.dart';

@collection
class CachedDashboardData {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? key; // 'dashboard_summary'

  String? json; // Storing the full JSON response for simplicity
  
  DateTime? lastUpdated;
}
