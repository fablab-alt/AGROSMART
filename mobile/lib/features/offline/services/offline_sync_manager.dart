import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'sync_queue_service.dart';
import 'package:agriculture/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Manages synchronization of offline data when connectivity is restored
class OfflineSyncManager {
  final ConnectivityService _connectivity;
  final SyncQueueService _syncQueue;
  final ApiClient _apiClient;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  static const int _maxRetries = 3;
  // Délai de retry potentiel pour futures implémentations
  // ignore: unused_field
  static const Duration _retryDelay = Duration(seconds: 5);

  OfflineSyncManager({
    required ConnectivityService connectivity,
    required SyncQueueService syncQueue,
    required ApiClient apiClient,
  }) : _connectivity = connectivity,
       _syncQueue = syncQueue,
       _apiClient = apiClient;

  /// Initialize and start listening for connectivity changes
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline && !_isSyncing) {
        syncPendingOperations();
      }
    });
  }

  /// Sync all pending operations
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      debugPrint('⏳ Sync already in progress');
      return SyncResult(
        synced: 0,
        failed: 0,
        remaining: await _syncQueue.getQueueSize(),
      );
    }

    if (!_connectivity.isOnline) {
      debugPrint('📵 Cannot sync - device is offline');
      return SyncResult(
        synced: 0,
        failed: 0,
        remaining: await _syncQueue.getQueueSize(),
      );
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    try {
      final operations = await _syncQueue.getQueue();
      debugPrint('🔄 Starting sync: ${operations.length} operations');

      for (final operation in operations) {
        try {
          final success = await _executeOperation(operation);
          if (success) {
            await _syncQueue.removeFromQueue(operation.id);
            synced++;
            debugPrint('✅ Synced: ${operation.type}');
          } else {
            failed++;
            // Update retry count
            if (operation.retryCount < _maxRetries) {
              // Leave in queue with incremented retry count
              debugPrint(
                '⚠️ Will retry: ${operation.type} (${operation.retryCount + 1}/$_maxRetries)',
              );
            } else {
              // Max retries reached, remove from queue
              await _syncQueue.removeFromQueue(operation.id);
              debugPrint('❌ Max retries reached: ${operation.type}');
            }
          }
        } catch (e) {
          failed++;
          debugPrint('❌ Sync error for ${operation.type}: $e');
        }
      }

      debugPrint('🏁 Sync complete: $synced synced, $failed failed');
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      synced: synced,
      failed: failed,
      remaining: await _syncQueue.getQueueSize(),
    );
  }

  /// Execute a single sync operation
  Future<bool> _executeOperation(SyncOperation operation) async {
    try {
      Response response;

      switch (operation.method.toUpperCase()) {
        case 'POST':
          response = await _apiClient.dio.post(
            operation.endpoint,
            data: operation.data,
          );
          break;
        case 'PUT':
          response = await _apiClient.dio.put(
            operation.endpoint,
            data: operation.data,
          );
          break;
        case 'PATCH':
          response = await _apiClient.dio.patch(
            operation.endpoint,
            data: operation.data,
          );
          break;
        case 'DELETE':
          response = await _apiClient.dio.delete(
            operation.endpoint,
            data: operation.data,
          );
          break;
        default:
          debugPrint('❌ Unknown HTTP method: ${operation.method}');
          return false;
      }

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      debugPrint('❌ DioException: ${e.message}');
      // Don't retry on 4xx errors (client errors)
      if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 400 &&
          e.response!.statusCode! < 500) {
        return true; // Remove from queue, it's a permanent error
      }
      return false;
    }
  }

  /// Force sync now
  Future<SyncResult> forceSyncNow() async {
    final isOnline = await _connectivity.checkConnectivity();
    if (!isOnline) {
      return SyncResult(
        synced: 0,
        failed: 0,
        remaining: await _syncQueue.getQueueSize(),
      );
    }
    return syncPendingOperations();
  }

  /// Get current sync status
  Future<SyncStatus> getStatus() async {
    final queueSize = await _syncQueue.getQueueSize();
    return SyncStatus(
      isOnline: _connectivity.isOnline,
      isSyncing: _isSyncing,
      pendingOperations: queueSize,
    );
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Result of a sync operation
class SyncResult {
  final int synced;
  final int failed;
  final int remaining;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.remaining,
  });

  bool get hasFailures => failed > 0;
  bool get isComplete => remaining == 0;
}

/// Current sync status
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingOperations;

  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingOperations,
  });

  bool get needsSync => pendingOperations > 0;
}
