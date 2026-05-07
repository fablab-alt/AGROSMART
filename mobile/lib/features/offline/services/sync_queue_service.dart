import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages offline data synchronization queue with priority support
class SyncQueueService {
  static const String _queueKey = 'offline_sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  final SharedPreferences _prefs;

  SyncQueueService(this._prefs);

  /// Add an operation to the sync queue with priority
  Future<void> addToQueue(
    SyncOperation operation, {
    SyncPriority priority = SyncPriority.normal,
  }) async {
    final queue = await getQueue();
    final newOperation = operation.copyWith(priority: priority);
    queue.add(newOperation);

    // Sort queue by priority
    queue.sort((a, b) {
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      return a.createdAt.compareTo(b.createdAt);
    });

    await _saveQueue(queue);
    debugPrint(
      '📥 Added to sync queue: ${operation.type} [${priority.name}] (${queue.length} items)',
    );
  }

  /// Get all pending operations
  Future<List<SyncOperation>> getQueue() async {
    final jsonString = _prefs.getString(_queueKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => SyncOperation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Error parsing sync queue: $e');
      return [];
    }
  }

  /// Get high priority operations first
  Future<List<SyncOperation>> getHighPriorityOperations() async {
    final queue = await getQueue();
    return queue
        .where(
          (op) =>
              op.priority == SyncPriority.high ||
              op.priority == SyncPriority.critical,
        )
        .toList();
  }

  /// Remove an operation from queue (after successful sync)
  Future<void> removeFromQueue(String operationId) async {
    final queue = await getQueue();
    queue.removeWhere((op) => op.id == operationId);
    await _saveQueue(queue);
  }

  /// Mark operation as failed and increment retry count
  Future<void> markAsFailed(String operationId) async {
    final queue = await getQueue();
    final index = queue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      queue[index] = queue[index].copyWith(
        retryCount: queue[index].retryCount + 1,
      );
      await _saveQueue(queue);
    }
  }

  /// Clear all operations from queue
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    final queue = await getQueue();
    return queue.length;
  }

  /// Get queue statistics
  Future<Map<String, int>> getQueueStats() async {
    final queue = await getQueue();
    return {
      'total': queue.length,
      'critical': queue
          .where((op) => op.priority == SyncPriority.critical)
          .length,
      'high': queue.where((op) => op.priority == SyncPriority.high).length,
      'normal': queue.where((op) => op.priority == SyncPriority.normal).length,
      'low': queue.where((op) => op.priority == SyncPriority.low).length,
      'failed': queue.where((op) => op.retryCount > 0).length,
    };
  }

  /// Save last sync timestamp
  Future<void> saveLastSyncTime(DateTime timestamp) async {
    await _prefs.setString(_lastSyncKey, timestamp.toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  Future<void> _saveQueue(List<SyncOperation> queue) async {
    final jsonString = json.encode(queue.map((e) => e.toJson()).toList());
    await _prefs.setString(_queueKey, jsonString);
  }
}

/// Priority levels for sync operations
enum SyncPriority { low, normal, high, critical }

/// Represents an operation to be synced when online
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final int retryCount;
  final SyncPriority priority;
  final int maxRetries;

  SyncOperation({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.data,
    DateTime? createdAt,
    this.retryCount = 0,
    this.priority = SyncPriority.normal,
    this.maxRetries = 3,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.byName(json['type'] as String),
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      priority: json['priority'] != null
          ? SyncPriority.values.byName(json['priority'] as String)
          : SyncPriority.normal,
      maxRetries: json['maxRetries'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'endpoint': endpoint,
    'method': method,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'priority': priority.name,
    'maxRetries': maxRetries,
  };

  SyncOperation copyWith({int? retryCount, SyncPriority? priority}) {
    return SyncOperation(
      id: id,
      type: type,
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
      maxRetries: maxRetries,
    );
  }

  bool get canRetry => retryCount < maxRetries;
}

enum SyncOperationType {
  createParcelle,
  updateParcelle,
  deleteParcelle,
  createDiagnostic,
  createMesure,
  updateProfile,
  createMessage,
  createStock,
  updateStock,
  createActivite,
  updateActivite,
  deleteActivite,
  other,
}
