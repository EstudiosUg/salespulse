import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/supplier.dart';
import '../models/user.dart';
import 'auth_provider.dart';

// API Service Provider - with authentication
final apiServiceProvider = Provider<ApiService>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final apiService = ApiService();

  // Set token if authenticated
  if (authState.token != null) {
    apiService.setToken(authState.token);
  }

  return apiService;
});

// Sales Providers
final salesProvider = FutureProvider<List<Sale>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSales();
});

final salesNotifierProvider =
    StateNotifierProvider<SalesNotifier, AsyncValue<List<Sale>>>((ref) {
  return SalesNotifier(ref.watch(apiServiceProvider));
});

class SalesNotifier extends StateNotifier<AsyncValue<List<Sale>>> {
  final ApiService _apiService;
  bool _isInitialLoadDone = false;

  SalesNotifier(this._apiService) : super(const AsyncValue.data([]));

  Future<void> loadSales({bool forceRefresh = false}) async {
    // Skip auto-loading, only load when explicitly called
    if (!forceRefresh && _isInitialLoadDone) return;

    // Don't show loading state if we already have data (background refresh)
    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      // Use pagination to load only recent 50 sales for faster performance
      final sales = await _apiService.getSalesWithFilters(perPage: 50);
      if (mounted) {
        state = AsyncValue.data(sales);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addSale(Sale sale) async {
    try {
      // Optimistic update - add to UI immediately
      final currentSales = state.value ?? [];
      final newSale = await _apiService.createSale(sale);

      if (mounted) {
        // Add the new sale at the beginning of the list
        state = AsyncValue.data([newSale, ...currentSales]);
      }
    } catch (error, stackTrace) {
      // Revert on error and reload
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadSales(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateSale(String id, Sale sale) async {
    try {
      final updatedSale = await _apiService.updateSale(id, sale);

      if (mounted) {
        // Update the specific sale in the list
        final currentSales = state.value ?? [];
        final updatedList =
            currentSales.map((s) => s.id == id ? updatedSale : s).toList();
        state = AsyncValue.data(updatedList);
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
      await _apiService.deleteSale(id);

      if (mounted) {
        // Remove the sale from the list
        final currentSales = state.value ?? [];
        final updatedList = currentSales.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  // Method to refresh data in background
  Future<void> refresh() async {
    await loadSales(forceRefresh: true);
  }
}

// Expenses Providers
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getExpenses();
});

final expensesNotifierProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier(ref.watch(apiServiceProvider));
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ApiService _apiService;
  bool _isInitialLoadDone = false;

  ExpensesNotifier(this._apiService) : super(const AsyncValue.data([]));

  Future<void> loadExpenses({bool forceRefresh = false}) async {
    // Skip auto-loading, only load when explicitly called
    if (!forceRefresh && _isInitialLoadDone) return;

    // Don't show loading state if we already have data (background refresh)
    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      // Use pagination to load only recent 50 expenses for faster performance
      final expenses = await _apiService.getExpensesWithFilters(perPage: 50);
      if (mounted) {
        state = AsyncValue.data(expenses);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // Optimistic update - add to UI immediately
      final currentExpenses = state.value ?? [];
      final newExpense = await _apiService.createExpense(expense);

      if (mounted) {
        // Add the new expense at the beginning of the list
        state = AsyncValue.data([newExpense, ...currentExpenses]);
      }
    } catch (error, stackTrace) {
      // Revert on error and reload
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadExpenses(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Expense expense) async {
    try {
      final updatedExpense = await _apiService.updateExpense(id, expense);

      if (mounted) {
        // Update the specific expense in the list
        final currentExpenses = state.value ?? [];
        final updatedList = currentExpenses
            .map((e) => e.id == id ? updatedExpense : e)
            .toList();
        state = AsyncValue.data(updatedList);
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
      await _apiService.deleteExpense(id);

      if (mounted) {
        // Remove the expense from the list
        final currentExpenses = state.value ?? [];
        final updatedList = currentExpenses.where((e) => e.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  // Method to refresh data in background
  Future<void> refresh() async {
    await loadExpenses(forceRefresh: true);
  }
}

// Dashboard Provider (cached - won't auto-dispose)
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  // Keep data in cache to reduce API calls
  ref.keepAlive();
  return apiService.getDashboardData();
});

// Enhanced Dashboard Providers (auto-cached by Riverpod)
final dashboardOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, int?>>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  // Riverpod automatically caches family providers based on params
  return apiService.getDashboardOverview(
    month: params['month'],
    year: params['year'],
  );
});

final unpaidCommissionsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  // Keep alive to cache unpaid commissions data
  ref.keepAlive();
  return apiService.getUnpaidCommissions();
});

final historyProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getHistory(
    month: params['month'],
    year: params['year'],
    type: params['type'],
  );
});

final monthlyStatsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMonthlyStats(year: year);
});

// Suppliers Providers
final suppliersProvider =
    FutureProvider.family<List<Supplier>, bool?>((ref, active) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSuppliers(active: active);
});

final suppliersNotifierProvider =
    StateNotifierProvider<SuppliersNotifier, AsyncValue<List<Supplier>>>((ref) {
  return SuppliersNotifier(ref.watch(apiServiceProvider));
});

class SuppliersNotifier extends StateNotifier<AsyncValue<List<Supplier>>> {
  final ApiService _apiService;
  bool _isInitialLoadDone = false;

  SuppliersNotifier(this._apiService) : super(const AsyncValue.data([]));

  Future<void> loadSuppliers({bool? active, bool forceRefresh = false}) async {
    // Skip auto-loading, only load when explicitly called
    if (!forceRefresh && _isInitialLoadDone) return;

    // Don't show loading state if we already have data (background refresh)
    if (!state.hasValue || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      final suppliers = await _apiService.getSuppliers(active: active);
      if (mounted) {
        state = AsyncValue.data(suppliers);
        _isInitialLoadDone = true;
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      // Optimistic update - add to UI immediately
      final currentSuppliers = state.value ?? [];
      final newSupplier = await _apiService.createSupplier(supplier);

      if (mounted) {
        // Add the new supplier to the list (sorted by name)
        final updatedList = [...currentSuppliers, newSupplier];
        updatedList.sort((a, b) => a.name.compareTo(b.name));
        state = AsyncValue.data(updatedList);
      }
    } catch (error, stackTrace) {
      // Revert on error and reload
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
        await loadSuppliers(forceRefresh: true);
      }
      rethrow;
    }
  }

  Future<void> updateSupplier(int id, Supplier supplier) async {
    try {
      final updatedSupplier = await _apiService.updateSupplier(id, supplier);

      if (mounted) {
        // Update the specific supplier in the list
        final currentSuppliers = state.value ?? [];
        final updatedList = currentSuppliers
            .map((s) => s.id == id ? updatedSupplier : s)
            .toList();
        updatedList.sort((a, b) => a.name.compareTo(b.name));
        state = AsyncValue.data(updatedList);
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
      await _apiService.deleteSupplier(id);

      if (mounted) {
        // Remove the supplier from the list
        final currentSuppliers = state.value ?? [];
        final updatedList = currentSuppliers.where((s) => s.id != id).toList();
        state = AsyncValue.data(updatedList);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  // Method to refresh data in background
  Future<void> refresh() async {
    await loadSuppliers(forceRefresh: true);
  }
}

// Profile Providers
final profileProvider = FutureProvider<User>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getProfile();
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<User?>>((ref) {
  return ProfileNotifier(ref.watch(apiServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _apiService;

  ProfileNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        state = AsyncValue.data(profile);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> updateProfile(User user) async {
    try {
      final updatedUser = await _apiService.updateProfile(user);
      if (mounted) {
        state = AsyncValue.data(updatedUser);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> uploadAvatar(dynamic imageFile) async {
    try {
      await _apiService.uploadAvatar(imageFile);
      await loadProfile(); // Refresh profile to get updated avatar
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Settings Providers
final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSettings();
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return SettingsNotifier(ref.watch(apiServiceProvider));
});

class SettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;

  SettingsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _apiService.getSettings();
      if (mounted) {
        state = AsyncValue.data(settings);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      final updatedSettings = await _apiService.updateSettings(settings);
      if (mounted) {
        state = AsyncValue.data(updatedSettings);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }
}

// Enhanced Sales Providers with Filtering
final salesWithFiltersProvider =
    FutureProvider.family<List<Sale>, Map<String, dynamic>>(
        (ref, filters) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSalesWithFilters(
    month: filters['month'],
    year: filters['year'],
    supplierId: filters['supplierId'],
    commissionPaid: filters['commissionPaid'],
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    perPage: filters['perPage'],
  );
});

// Enhanced Expenses Providers with Filtering
final expensesWithFiltersProvider =
    FutureProvider.family<List<Expense>, Map<String, dynamic>>(
        (ref, filters) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getExpensesWithFilters(
    month: filters['month'],
    year: filters['year'],
    startDate: filters['startDate'],
    endDate: filters['endDate'],
    perPage: filters['perPage'],
  );
});

// Export Provider
final exportDataProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.exportData(
    startDate: params['startDate'],
    endDate: params['endDate'],
    includeSales: params['includeSales'],
    includeExpenses: params['includeExpenses'],
  );
});

// Dashboard StateNotifier for auto-loading and refreshing
final dashboardNotifierProvider =
    StateNotifierProvider<DashboardNotifier, AsyncValue<Map<String, dynamic>>>(
        (ref) {
  return DashboardNotifier(ref.watch(apiServiceProvider));
});

class DashboardNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;
  int? _currentMonth;
  int? _currentYear;

  DashboardNotifier(this._apiService) : super(const AsyncValue.loading()) {
    // Auto-load on creation with current month
    final now = DateTime.now();
    loadDashboard(month: now.month, year: now.year);
  }

  Future<void> loadDashboard({int? month, int? year}) async {
    _currentMonth = month;
    _currentYear = year;

    // Don't show loading if we already have data (background refresh)
    if (!state.hasValue || (state.value?.isEmpty ?? true)) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _apiService.getDashboardOverview(
        month: month,
        year: year,
      );

      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() async {
    await loadDashboard(month: _currentMonth, year: _currentYear);
  }

  void updateMonthYear(int? month, int? year) {
    loadDashboard(month: month, year: year);
  }
}

// Unpaid Commissions StateNotifier
final unpaidCommissionsNotifierProvider = StateNotifierProvider<
    UnpaidCommissionsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  return UnpaidCommissionsNotifier(ref.watch(apiServiceProvider));
});

class UnpaidCommissionsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiService _apiService;

  UnpaidCommissionsNotifier(this._apiService)
      : super(const AsyncValue.loading()) {
    // Auto-load on creation
    loadUnpaidCommissions();
  }

  Future<void> loadUnpaidCommissions() async {
    // Don't show loading if we already have data
    if (!state.hasValue || (state.value?.isEmpty ?? true)) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _apiService.getUnpaidCommissions();

      if (mounted) {
        state = AsyncValue.data(data);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() async {
    await loadUnpaidCommissions();
  }
}
