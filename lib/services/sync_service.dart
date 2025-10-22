import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';
import '../providers/api_provider.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/supplier.dart';
import 'dart:async';

/// Service to sync offline operations when online
class SyncService {
  final ApiService _apiService;
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get onSyncStatusChanged => _syncStatusController.stream;

  SyncService(this._apiService, this._localStorage, this._connectivity) {
    // Listen for connectivity changes and auto-sync
    _connectivity.onConnectivityChanged.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        syncPendingOperations();
      }
    });
  }

  /// Sync all pending operations with the server
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    if (!_connectivity.isConnected) {
      return SyncResult(success: false, message: 'No internet connection');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final queue = await _localStorage.getSyncQueue();

      if (queue.isEmpty) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus.idle);
        return SyncResult(success: true, message: 'Nothing to sync');
      }

      int successCount = 0;
      int failCount = 0;
      final errors = <String>[];

      // Process each operation in queue
      for (final operation in queue) {
        try {
          await _processOperation(operation);

          // Remove from queue on success
          final queueKey = operation['_queueKey'];
          if (queueKey != null) {
            await _localStorage.removeFromSyncQueue(queueKey);
          }

          successCount++;
        } catch (e) {
          failCount++;
          errors.add(e.toString());
          debugPrint('Error syncing operation: $e');
        }
      }

      // Refresh data from server after sync
      await _refreshDataFromServer();

      _isSyncing = false;

      if (failCount == 0) {
        _syncStatusController.add(SyncStatus.success);
        return SyncResult(
          success: true,
          message: 'Successfully synced $successCount operation(s)',
          syncedCount: successCount,
        );
      } else {
        _syncStatusController.add(SyncStatus.failed);
        return SyncResult(
          success: false,
          message: 'Synced $successCount, failed $failCount',
          syncedCount: successCount,
          failedCount: failCount,
          errors: errors,
        );
      }
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.failed);
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        errors: [e.toString()],
      );
    }
  }

  Future<void> _processOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final entity = operation['entity'] as String;
    final data = operation['data'] as Map<String, dynamic>?;
    final id = operation['id'];

    switch (entity) {
      case 'sale':
        await _processSaleOperation(type, data, id);
        break;
      case 'expense':
        await _processExpenseOperation(type, data, id);
        break;
      case 'supplier':
        await _processSupplierOperation(type, data, id);
        break;
      default:
        throw Exception('Unknown entity type: $entity');
    }
  }

  Future<void> _processSaleOperation(
    String type,
    Map<String, dynamic>? data,
    dynamic id,
  ) async {
    switch (type) {
      case 'create':
        if (data != null) {
          final sale = Sale.fromJson(data);
          await _apiService.createSale(sale);
        }
        break;
      case 'update':
        if (data != null && id != null) {
          final sale = Sale.fromJson(data);
          await _apiService.updateSale(id.toString(), sale);
        }
        break;
      case 'delete':
        if (id != null) {
          await _apiService.deleteSale(id.toString());
        }
        break;
    }
  }

  Future<void> _processExpenseOperation(
    String type,
    Map<String, dynamic>? data,
    dynamic id,
  ) async {
    switch (type) {
      case 'create':
        if (data != null) {
          final expense = Expense.fromJson(data);
          await _apiService.createExpense(expense);
        }
        break;
      case 'update':
        if (data != null && id != null) {
          final expense = Expense.fromJson(data);
          await _apiService.updateExpense(id.toString(), expense);
        }
        break;
      case 'delete':
        if (id != null) {
          await _apiService.deleteExpense(id.toString());
        }
        break;
    }
  }

  Future<void> _processSupplierOperation(
    String type,
    Map<String, dynamic>? data,
    dynamic id,
  ) async {
    switch (type) {
      case 'create':
        if (data != null) {
          final supplier = Supplier.fromJson(data);
          await _apiService.createSupplier(supplier);
        }
        break;
      case 'update':
        if (data != null && id != null) {
          final supplier = Supplier.fromJson(data);
          await _apiService.updateSupplier(id as int, supplier);
        }
        break;
      case 'delete':
        if (id != null) {
          await _apiService.deleteSupplier(id as int);
        }
        break;
    }
  }

  Future<void> _refreshDataFromServer() async {
    try {
      // Fetch latest data from server
      final sales = await _apiService.getSalesWithFilters(perPage: 100);
      final expenses = await _apiService.getExpensesWithFilters(perPage: 100);
      final suppliers = await _apiService.getSuppliers();

      // Save to local storage
      await _localStorage.saveSales(sales);
      await _localStorage.saveExpenses(expenses);
      await _localStorage.saveSuppliers(suppliers);

      // Update last sync time
      await _localStorage.setLastSyncTime('sales', DateTime.now());
      await _localStorage.setLastSyncTime('expenses', DateTime.now());
      await _localStorage.setLastSyncTime('suppliers', DateTime.now());
    } catch (e) {
      debugPrint('Error refreshing data from server: $e');
    }
  }

  void dispose() {
    _syncStatusController.close();
  }
}

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final localStorage = LocalStorageService();
  final connectivity = ref.watch(connectivityServiceProvider);

  final service = SyncService(apiService, localStorage, connectivity);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.onSyncStatusChanged;
});
