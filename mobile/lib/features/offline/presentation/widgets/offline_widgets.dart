import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/offline_bloc.dart';

/// Banner showing offline status
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        if (state.isOnline) return const SizedBox.shrink();
        
        return MaterialBanner(
          backgroundColor: Colors.orange.shade100,
          leading: const Icon(Icons.wifi_off, color: Colors.orange),
          content: const Text(
            'Mode hors ligne - Les modifications seront synchronisées lorsque vous serez connecté',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<OfflineBloc>().add(CheckConnectivity());
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }
}

/// Small offline indicator for app bar
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        if (state.isOnline) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'Hors ligne',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Sync status widget with pending count
class SyncStatusWidget extends StatelessWidget {
  final VoidCallback? onSyncPressed;

  const SyncStatusWidget({super.key, this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        if (state.pendingOperations == 0) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              if (state.isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.isSyncing
                          ? 'Synchronisation en cours...'
                          : '${state.pendingOperations} élément(s) à synchroniser',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (!state.isOnline)
                      Text(
                        'En attente de connexion',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (state.isOnline && !state.isSyncing && onSyncPressed != null)
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: onSyncPressed,
                  tooltip: 'Synchroniser maintenant',
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Wrapper widget that handles offline state
class OfflineAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showBanner;

  const OfflineAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineBloc, OfflineState>(
      builder: (context, state) {
        return Column(
          children: [
            if (showBanner && !state.isOnline)
              const OfflineBanner(),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
