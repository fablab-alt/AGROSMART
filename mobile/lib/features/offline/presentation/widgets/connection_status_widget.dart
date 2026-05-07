import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_info.dart';

/// Widget displaying connection status indicator
class ConnectionStatusWidget extends StatelessWidget {
  final bool showWhenOnline;

  const ConnectionStatusWidget({super.key, this.showWhenOnline = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.read<NetworkInfo>().onConnectivityChanged,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (isConnected && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isConnected ? Colors.green : Colors.orange,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'En ligne' : 'Mode hors ligne',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Banner showing sync status
class SyncStatusBanner extends StatelessWidget {
  final int pendingOperations;
  final VoidCallback? onTapSync;

  const SyncStatusBanner({
    super.key,
    required this.pendingOperations,
    this.onTapSync,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingOperations == 0) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      backgroundColor: Colors.orange.shade100,
      leading: const Icon(Icons.sync, color: Colors.orange),
      content: Text(
        '$pendingOperations opération(s) en attente de synchronisation',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(onPressed: onTapSync, child: const Text('Synchroniser')),
      ],
    );
  }
}

/// Floating indicator for connection status
class ConnectionFloatingIndicator extends StatelessWidget {
  const ConnectionFloatingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: context.read<NetworkInfo>().onConnectivityChanged,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          top: isConnected ? -50 : 10,
          right: 10,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            color: isConnected ? Colors.green : Colors.red,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? 'Connecté' : 'Hors ligne',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
