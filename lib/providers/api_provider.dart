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

  SalesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadSales();
  }

  Future<void> loadSales() async {
    state = const AsyncValue.loading();
    try {
      final sales = await _apiService.getSales();
      if (mounted) {
        state = AsyncValue.data(sales);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addSale(Sale sale) async {
    try {
      await _apiService.createSale(sale);
      await loadSales(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<void> updateSale(String id, Sale sale) async {
    try {
      await _apiService.updateSale(id, sale);
      await loadSales(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      await _apiService.deleteSale(id);
      await loadSales(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
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

  ExpensesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _apiService.getExpenses();
      if (mounted) {
        state = AsyncValue.data(expenses);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _apiService.createExpense(expense);
      await loadExpenses(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<void> updateExpense(String id, Expense expense) async {
    try {
      await _apiService.updateExpense(id, expense);
      await loadExpenses(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _apiService.deleteExpense(id);
      await loadExpenses(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow; // Rethrow to let the UI handle the error
    }
  }
}

// Dashboard Provider
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboardData();
});

// Enhanced Dashboard Providers
final dashboardOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, int?>>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDashboardOverview(
    month: params['month'],
    year: params['year'],
  );
});

final unpaidCommissionsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
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

  SuppliersNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadSuppliers();
  }

  Future<void> loadSuppliers({bool? active}) async {
    state = const AsyncValue.loading();
    try {
      final suppliers = await _apiService.getSuppliers(active: active);
      if (mounted) {
        state = AsyncValue.data(suppliers);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      await _apiService.createSupplier(supplier);
      await loadSuppliers(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateSupplier(int id, Supplier supplier) async {
    try {
      await _apiService.updateSupplier(id, supplier);
      await loadSuppliers(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _apiService.deleteSupplier(id);
      await loadSuppliers(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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
