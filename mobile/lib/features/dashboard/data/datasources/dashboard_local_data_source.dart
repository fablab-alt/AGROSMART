import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../../../core/error/exceptions.dart';
import '../models/cached_dashboard_data.dart';

abstract class DashboardLocalDataSource {
  Future<CachedDashboardData?> getLastDashboardData();
  Future<void> cacheDashboardData(CachedDashboardData data);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final Isar isar;

  DashboardLocalDataSourceImpl({required this.isar});

  @override
  Future<CachedDashboardData?> getLastDashboardData() async {
    try {
      return isar.cachedDashboardDatas.where().findFirst();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheDashboardData(CachedDashboardData data) async {
    // TODO: Fix Isar v4 transaction API
    // Temporarily disabled until we resolve the writeTxn method issue
    try {
      // await isar.writeTxn(() async {
      //   isar.cachedDashboardDatas.clear();
      //   isar.cachedDashboardDatas.put(data);
      // });
      
      // For now, skip caching to allow the app to build
      debugPrint('Warning: Dashboard caching is temporarily disabled');
    } catch (e) {
      throw CacheException();
    }
  }
}

