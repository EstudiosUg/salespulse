import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/supplier.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/connectivity_service.dart';
import 'api_provider.dart';

const _uuid = Uuid();

/// Offline-capable Sales Notifier
class OfflineSalesNotifier extends StateNotifier<AsyncValue<List<Sale>>> {
  final ApiService _apiService;
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;
  bool _isInitialLoadDone = false;

  OfflineSalesNotifier(
    this._apiService,
    this._localStorage,
    this._connectivity,
  ) : super(const AsyncValue.data([])) {
    _loadFromLocal();
  }

  /// Load data from local storage first (instant)
  Future<void> _loadFromLocal() async {
    try {
      final localSales = await _localStorage.getSales();
      if (mounted) {
        state = AsyncValue.data(localSales);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Load from server and update local storage
  Future<void> loadSales({bool forceRefresh = false}) async {
    if (!forceRefresh && _isInitialLoadDone && !_connectivity.isConnected) {
      // Use cached data when offline
      return;
    }

    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      if (_connectivity.isConnected) {
        // Fetch from server
        final sales = await _apiService.getSalesWithFilters(perPage: 100);
        await _localStorage.saveSales(sales);

        if (mounted) {
          state = AsyncValue.data(sales);
          _isInitialLoadDone = true;
        }
      } else {
        // Load from local storage when offline
        await _loadFromLocal();
      }
    } catch (error, _) {
      if (mounted) {
        // On error, try to load from local storage
        await _loadFromLocal();
      }
    }
  }

  Future<void> addSale(Sale sale) async {
    try {
      final currentSales = state.value ?? [];

      // Generate temporary ID if offline
      final saleToAdd =
          sale.id.isEmpty ? sale.copyWith(id: 'temp_${_uuid.v4()}') : sale;

      // Add to UI immediately (optimistic update)
      if (mounted) {
        state = AsyncValue.data([saleToAdd, ...currentSales]);
      }

      // Save to local storage
      await _localStorage.saveSale(saleToAdd);

      if (_connectivity.isConnected) {
        // Save to server if online
        final newSale = await _apiService.createSale(saleToAdd);

        // Update with server-generated ID
        if (mounted) {
          final updatedSales = currentSales
              .map((s) => s.id == saleToAdd.id ? newSale : s)
              .toList();
          state = AsyncValue.data(
              [newSale, ...updatedSales.where((s) => s.id != saleToAdd.id)]);
        }

        // Update local storage with server version
        await _localStorage.saveSale(newSale);
      } else {
        // Queue for sync when offline
        await _localStorage.addToSyncQueue({
          'type': 'create',
          'entity': 'sale',
          'data': saleToAdd.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadSales(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateSale(String id, Sale sale) async {
    try {
      final currentSales = state.value ?? [];

      // Update UI immediately
      if (mounted) {
        final updatedList =
            currentSales.map((s) => s.id == id ? sale : s).toList();
        state = AsyncValue.data(updatedList);
      }

      // Update local storage
      await _localStorage.saveSale(sale);

      if (_connectivity.isConnected) {
        // Update on server if online
        final updatedSale = await _apiService.updateSale(id, sale);
        await _localStorage.saveSale(updatedSale);

        if (mounted) {
          final updatedList =
              currentSales.map((s) => s.id == id ? updatedSale : s).toList();
          state = AsyncValue.data(updatedList);
        }
      } else {
        // Queue for sync when offline
        await _localStorage.addToSyncQueue({
          'type': 'update',
          'entity': 'sale',
          'id': id,
          'data': sale.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      final currentSales = state.value ?? [];

      // Remove from UI immediately
      if (mounted) {
        final updatedList = currentSales.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      }

      // Remove from local storage
      await _localStorage.deleteSale(id);

      if (_connectivity.isConnected) {
        // Delete on server if online
        await _apiService.deleteSale(id);
      } else {
        // Queue for sync when offline
        await _localStorage.addToSyncQueue({
          'type': 'delete',
          'entity': 'sale',
          'id': id,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadSales(forceRefresh: true);
  }
}

/// Offline-capable Expenses Notifier
class OfflineExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ApiService _apiService;
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;
  bool _isInitialLoadDone = false;

  OfflineExpensesNotifier(
    this._apiService,
    this._localStorage,
    this._connectivity,
  ) : super(const AsyncValue.data([])) {
    _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    try {
      final localExpenses = await _localStorage.getExpenses();
      if (mounted) {
        state = AsyncValue.data(localExpenses);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> loadExpenses({bool forceRefresh = false}) async {
    if (!forceRefresh && _isInitialLoadDone && !_connectivity.isConnected) {
      return;
    }

    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      if (_connectivity.isConnected) {
        final expenses = await _apiService.getExpensesWithFilters(perPage: 100);
        await _localStorage.saveExpenses(expenses);

        if (mounted) {
          state = AsyncValue.data(expenses);
          _isInitialLoadDone = true;
        }
      } else {
        await _loadFromLocal();
      }
    } catch (error, _) {
      if (mounted) {
        await _loadFromLocal();
      }
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final currentExpenses = state.value ?? [];
      final expenseToAdd = expense.id.isEmpty
          ? expense.copyWith(id: 'temp_${_uuid.v4()}')
          : expense;

      if (mounted) {
        state = AsyncValue.data([expenseToAdd, ...currentExpenses]);
      }

      await _localStorage.saveExpense(expenseToAdd);

      if (_connectivity.isConnected) {
        final newExpense = await _apiService.createExpense(expenseToAdd);

        if (mounted) {
          final updatedExpenses = currentExpenses
              .map((e) => e.id == expenseToAdd.id ? newExpense : e)
              .toList();
          state = AsyncValue.data([
            newExpense,
            ...updatedExpenses.where((e) => e.id != expenseToAdd.id)
          ]);
        }

        await _localStorage.saveExpense(newExpense);
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'create',
          'entity': 'expense',
          'data': expenseToAdd.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadExpenses(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Expense expense) async {
    try {
      final currentExpenses = state.value ?? [];

      if (mounted) {
        final updatedList =
            currentExpenses.map((e) => e.id == id ? expense : e).toList();
        state = AsyncValue.data(updatedList);
      }

      await _localStorage.saveExpense(expense);

      if (_connectivity.isConnected) {
        final updatedExpense = await _apiService.updateExpense(id, expense);
        await _localStorage.saveExpense(updatedExpense);

        if (mounted) {
          final updatedList = currentExpenses
              .map((e) => e.id == id ? updatedExpense : e)
              .toList();
          state = AsyncValue.data(updatedList);
        }
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'update',
          'entity': 'expense',
          'id': id,
          'data': expense.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final currentExpenses = state.value ?? [];

      if (mounted) {
        final updatedList = currentExpenses.where((e) => e.id != id).toList();
        state = AsyncValue.data(updatedList);
      }

      await _localStorage.deleteExpense(id);

      if (_connectivity.isConnected) {
        await _apiService.deleteExpense(id);
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'delete',
          'entity': 'expense',
          'id': id,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadExpenses(forceRefresh: true);
  }
}

/// Offline-capable Suppliers Notifier
class OfflineSuppliersNotifier
    extends StateNotifier<AsyncValue<List<Supplier>>> {
  final ApiService _apiService;
  final LocalStorageService _localStorage;
  final ConnectivityService _connectivity;
  bool _isInitialLoadDone = false;

  OfflineSuppliersNotifier(
    this._apiService,
    this._localStorage,
    this._connectivity,
  ) : super(const AsyncValue.data([])) {
    _loadFromLocal();
  }

  Future<void> _loadFromLocal() async {
    try {
      final localSuppliers = await _localStorage.getSuppliers();
      if (mounted) {
        state = AsyncValue.data(localSuppliers);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> loadSuppliers({bool? active, bool forceRefresh = false}) async {
    if (!forceRefresh && _isInitialLoadDone && !_connectivity.isConnected) {
      return;
    }

    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      if (_connectivity.isConnected) {
        final suppliers = await _apiService.getSuppliers(active: active);
        await _localStorage.saveSuppliers(suppliers);

        if (mounted) {
          state = AsyncValue.data(suppliers);
          _isInitialLoadDone = true;
        }
      } else {
        await _loadFromLocal();
      }
    } catch (error, _) {
      if (mounted) {
        await _loadFromLocal();
      }
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      final currentSuppliers = state.value ?? [];
      final supplierToAdd = supplier.id == 0
          ? supplier.copyWith(id: DateTime.now().millisecondsSinceEpoch)
          : supplier;

      final updatedList = [...currentSuppliers, supplierToAdd];
      updatedList.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        state = AsyncValue.data(updatedList);
      }

      await _localStorage.saveSupplier(supplierToAdd);

      if (_connectivity.isConnected) {
        final newSupplier = await _apiService.createSupplier(supplierToAdd);

        final finalList = currentSuppliers
            .map((s) => s.id == supplierToAdd.id ? newSupplier : s)
            .toList()
          ..add(newSupplier);
        finalList.sort((a, b) => a.name.compareTo(b.name));

        if (mounted) {
          state = AsyncValue.data(finalList
              .where((s) => s.id == newSupplier.id || s.id != supplierToAdd.id)
              .toList());
        }

        await _localStorage.saveSupplier(newSupplier);
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'create',
          'entity': 'supplier',
          'data': supplierToAdd.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadSuppliers(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateSupplier(int id, Supplier supplier) async {
    try {
      final currentSuppliers = state.value ?? [];

      final updatedList =
          currentSuppliers.map((s) => s.id == id ? supplier : s).toList();
      updatedList.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        state = AsyncValue.data(updatedList);
      }

      await _localStorage.saveSupplier(supplier);

      if (_connectivity.isConnected) {
        final updatedSupplier = await _apiService.updateSupplier(id, supplier);
        await _localStorage.saveSupplier(updatedSupplier);

        final finalList = currentSuppliers
            .map((s) => s.id == id ? updatedSupplier : s)
            .toList();
        finalList.sort((a, b) => a.name.compareTo(b.name));

        if (mounted) {
          state = AsyncValue.data(finalList);
        }
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'update',
          'entity': 'supplier',
          'id': id,
          'data': supplier.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      final currentSuppliers = state.value ?? [];

      if (mounted) {
        final updatedList = currentSuppliers.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      }

      await _localStorage.deleteSupplier(id);

      if (_connectivity.isConnected) {
        await _apiService.deleteSupplier(id);
      } else {
        await _localStorage.addToSyncQueue({
          'type': 'delete',
          'entity': 'supplier',
          'id': id,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadSuppliers(forceRefresh: true);
  }
}

/// Offline-aware providers (replace the online-only ones)
final offlineSalesNotifierProvider =
    StateNotifierProvider<OfflineSalesNotifier, AsyncValue<List<Sale>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final localStorage = LocalStorageService();
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineSalesNotifier(apiService, localStorage, connectivity);
});

final offlineExpensesNotifierProvider =
    StateNotifierProvider<OfflineExpensesNotifier, AsyncValue<List<Expense>>>(
        (ref) {
  final apiService = ref.watch(apiServiceProvider);
  final localStorage = LocalStorageService();
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineExpensesNotifier(apiService, localStorage, connectivity);
});

final offlineSuppliersNotifierProvider =
    StateNotifierProvider<OfflineSuppliersNotifier, AsyncValue<List<Supplier>>>(
        (ref) {
  final apiService = ref.watch(apiServiceProvider);
  final localStorage = LocalStorageService();
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineSuppliersNotifier(apiService, localStorage, connectivity);
});
