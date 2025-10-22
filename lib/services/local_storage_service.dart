import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/supplier.dart';

/// Service for local data storage using Hive
class LocalStorageService {
  static const String salesBox = 'sales';
  static const String expensesBox = 'expenses';
  static const String suppliersBox = 'suppliers';
  static const String syncQueueBox = 'sync_queue';
  static const String lastSyncBox = 'last_sync';

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Open boxes for offline storage
    await Hive.openBox<Map>(salesBox);
    await Hive.openBox<Map>(expensesBox);
    await Hive.openBox<Map>(suppliersBox);
    await Hive.openBox<Map>(syncQueueBox);
    await Hive.openBox<String>(lastSyncBox);
  }

  // ===== SALES =====

  Future<void> saveSales(List<Sale> sales) async {
    final box = Hive.box<Map>(salesBox);
    await box.clear();

    for (final sale in sales) {
      await box.put(sale.id, sale.toJson());
    }
  }

  Future<List<Sale>> getSales() async {
    final box = Hive.box<Map>(salesBox);
    final sales = <Sale>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null) {
          sales.add(Sale.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (e) {
        debugPrint('Error loading sale $key: $e');
      }
    }

    return sales;
  }

  Future<void> saveSale(Sale sale) async {
    final box = Hive.box<Map>(salesBox);
    await box.put(sale.id, sale.toJson());
  }

  Future<void> deleteSale(String id) async {
    final box = Hive.box<Map>(salesBox);
    await box.delete(id);
  }

  // ===== EXPENSES =====

  Future<void> saveExpenses(List<Expense> expenses) async {
    final box = Hive.box<Map>(expensesBox);
    await box.clear();

    for (final expense in expenses) {
      await box.put(expense.id, expense.toJson());
    }
  }

  Future<List<Expense>> getExpenses() async {
    final box = Hive.box<Map>(expensesBox);
    final expenses = <Expense>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null) {
          expenses.add(Expense.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (e) {
        debugPrint('Error loading expense $key: $e');
      }
    }

    return expenses;
  }

  Future<void> saveExpense(Expense expense) async {
    final box = Hive.box<Map>(expensesBox);
    await box.put(expense.id, expense.toJson());
  }

  Future<void> deleteExpense(String id) async {
    final box = Hive.box<Map>(expensesBox);
    await box.delete(id);
  }

  // ===== SUPPLIERS =====

  Future<void> saveSuppliers(List<Supplier> suppliers) async {
    final box = Hive.box<Map>(suppliersBox);
    await box.clear();

    for (final supplier in suppliers) {
      await box.put(supplier.id, supplier.toJson());
    }
  }

  Future<List<Supplier>> getSuppliers() async {
    final box = Hive.box<Map>(suppliersBox);
    final suppliers = <Supplier>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null) {
          suppliers.add(Supplier.fromJson(Map<String, dynamic>.from(data)));
        }
      } catch (e) {
        debugPrint('Error loading supplier $key: $e');
      }
    }

    return suppliers;
  }

  Future<void> saveSupplier(Supplier supplier) async {
    final box = Hive.box<Map>(suppliersBox);
    await box.put(supplier.id, supplier.toJson());
  }

  Future<void> deleteSupplier(int id) async {
    final box = Hive.box<Map>(suppliersBox);
    await box.delete(id);
  }

  // ===== SYNC QUEUE =====

  Future<void> addToSyncQueue(Map<String, dynamic> operation) async {
    final box = Hive.box<Map>(syncQueueBox);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await box.put(timestamp, operation);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final box = Hive.box<Map>(syncQueueBox);
    final queue = <Map<String, dynamic>>[];

    for (final key in box.keys) {
      final data = box.get(key);
      if (data != null) {
        final operation = Map<String, dynamic>.from(data);
        operation['_queueKey'] = key; // Store key for deletion after sync
        queue.add(operation);
      }
    }

    return queue;
  }

  Future<void> removeFromSyncQueue(dynamic key) async {
    final box = Hive.box<Map>(syncQueueBox);
    await box.delete(key);
  }

  Future<void> clearSyncQueue() async {
    final box = Hive.box<Map>(syncQueueBox);
    await box.clear();
  }

  // ===== LAST SYNC =====

  Future<void> setLastSyncTime(String key, DateTime time) async {
    final box = Hive.box<String>(lastSyncBox);
    await box.put(key, time.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime(String key) async {
    final box = Hive.box<String>(lastSyncBox);
    final timeStr = box.get(key);
    if (timeStr != null) {
      return DateTime.parse(timeStr);
    }
    return null;
  }

  // ===== CLEAR ALL =====

  Future<void> clearAll() async {
    await Hive.box<Map>(salesBox).clear();
    await Hive.box<Map>(expensesBox).clear();
    await Hive.box<Map>(suppliersBox).clear();
    await Hive.box<Map>(syncQueueBox).clear();
    await Hive.box<String>(lastSyncBox).clear();
  }
}
