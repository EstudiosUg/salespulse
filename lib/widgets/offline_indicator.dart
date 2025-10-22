import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Widget that shows offline status and sync indicator
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    
    // Don't show anything if online and not syncing
    if (connectivity.isConnected && syncStatus.value != SyncStatus.syncing) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(connectivity.isConnected, syncStatus.value),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getIcon(connectivity.isConnected, syncStatus.value),
          const SizedBox(width: 6),
          Text(
            _getMessage(connectivity.isConnected, syncStatus.value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getBackgroundColor(bool isConnected, SyncStatus? syncStatus) {
    if (syncStatus == SyncStatus.syncing) {
      return Colors.blue;
    } else if (syncStatus == SyncStatus.success) {
      return Colors.green;
    } else if (syncStatus == SyncStatus.failed) {
      return Colors.red;
    } else if (!isConnected) {
      return Colors.orange;
    }
    return Colors.grey;
  }
  
  Widget _getIcon(bool isConnected, SyncStatus? syncStatus) {
    if (syncStatus == SyncStatus.syncing) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (syncStatus == SyncStatus.success) {
      return const Icon(Icons.check_circle, color: Colors.white, size: 14);
    } else if (syncStatus == SyncStatus.failed) {
      return const Icon(Icons.error, color: Colors.white, size: 14);
    } else if (!isConnected) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 14);
    }
    return const Icon(Icons.cloud_done, color: Colors.white, size: 14);
  }
  
  String _getMessage(bool isConnected, SyncStatus? syncStatus) {
    if (syncStatus == SyncStatus.syncing) {
      return 'Syncing...';
    } else if (syncStatus == SyncStatus.success) {
      return 'Synced';
    } else if (syncStatus == SyncStatus.failed) {
      return 'Sync failed';
    } else if (!isConnected) {
      return 'Offline mode';
    }
    return 'Online';
  }
}

/// Banner to show offline status at the top of screens
class OfflineBanner extends ConsumerWidget {
  final Widget child;
  
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    final syncService = ref.watch(syncServiceProvider);
    
    return Column(
      children: [
        if (!connectivity.isConnected)
          Container(
            width: double.infinity,
            color: Colors.orange.shade700,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You\'re offline. Changes will sync when online.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (syncService.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

