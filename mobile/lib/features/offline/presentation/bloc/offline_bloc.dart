import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_sync_manager.dart';
import '../../services/sync_queue_service.dart';

// Events
abstract class OfflineEvent extends Equatable {
  const OfflineEvent();
  
  @override
  List<Object?> get props => [];
}

class InitializeOffline extends OfflineEvent {}

class ConnectivityChanged extends OfflineEvent {
  final bool isOnline;
  const ConnectivityChanged(this.isOnline);
  
  @override
  List<Object?> get props => [isOnline];
}

class CheckConnectivity extends OfflineEvent {}

class SyncNow extends OfflineEvent {}

class QueueOperation extends OfflineEvent {
  final SyncOperation operation;
  const QueueOperation(this.operation);
  
  @override
  List<Object?> get props => [operation];
}

class ClearQueue extends OfflineEvent {}

// State
class OfflineState extends Equatable {
  final bool isOnline;
  final bool isSyncing;
  final int pendingOperations;
  final String? lastError;

  const OfflineState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingOperations = 0,
    this.lastError,
  });

  OfflineState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingOperations,
    String? lastError,
  }) {
    return OfflineState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [isOnline, isSyncing, pendingOperations, lastError];
}

// BLoC
class OfflineBloc extends Bloc<OfflineEvent, OfflineState> {
  final ConnectivityService _connectivity;
  final OfflineSyncManager _syncManager;
  final SyncQueueService _syncQueue;

  OfflineBloc({
    required ConnectivityService connectivity,
    required OfflineSyncManager syncManager,
    required SyncQueueService syncQueue,
  })  : _connectivity = connectivity,
        _syncManager = syncManager,
        _syncQueue = syncQueue,
        super(const OfflineState()) {
    on<InitializeOffline>(_onInitialize);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);
    on<SyncNow>(_onSyncNow);
    on<QueueOperation>(_onQueueOperation);
    on<ClearQueue>(_onClearQueue);
  }

  Future<void> _onInitialize(
    InitializeOffline event,
    Emitter<OfflineState> emit,
  ) async {
    await _connectivity.initialize();
    _syncManager.initialize();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChanged(isOnline));
    });
    
    // Get initial state
    final isOnline = _connectivity.isOnline;
    final pendingOps = await _syncQueue.getQueueSize();
    
    emit(state.copyWith(
      isOnline: isOnline,
      pendingOperations: pendingOps,
    ));
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<OfflineState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    
    // Auto-sync when coming back online
    if (event.isOnline && state.pendingOperations > 0) {
      add(SyncNow());
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<OfflineState> emit,
  ) async {
    final isOnline = await _connectivity.checkConnectivity();
    emit(state.copyWith(isOnline: isOnline));
    
    if (isOnline && state.pendingOperations > 0) {
      add(SyncNow());
    }
  }

  Future<void> _onSyncNow(
    SyncNow event,
    Emitter<OfflineState> emit,
  ) async {
    if (!state.isOnline || state.isSyncing) return;
    
    emit(state.copyWith(isSyncing: true));
    
    try {
      final result = await _syncManager.forceSyncNow();
      emit(state.copyWith(
        isSyncing: false,
        pendingOperations: result.remaining,
        lastError: result.hasFailures ? 'Certaines opérations ont échoué' : null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      ));
    }
  }

  Future<void> _onQueueOperation(
    QueueOperation event,
    Emitter<OfflineState> emit,
  ) async {
    await _syncQueue.addToQueue(event.operation);
    final pendingOps = await _syncQueue.getQueueSize();
    emit(state.copyWith(pendingOperations: pendingOps));
  }

  Future<void> _onClearQueue(
    ClearQueue event,
    Emitter<OfflineState> emit,
  ) async {
    await _syncQueue.clearQueue();
    emit(state.copyWith(pendingOperations: 0));
  }

  @override
  Future<void> close() {
    _connectivity.dispose();
    _syncManager.dispose();
    return super.close();
  }
}
