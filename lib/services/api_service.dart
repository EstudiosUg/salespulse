import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../models/sale.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../models/supplier.dart';
import '../config/api_config.dart';

class ApiService {
  // Use API configuration instead of hardcoded URLs
  static String get baseUrl => ApiConfig.apiUrl;
  static String get storageUrl => ApiConfig.storageUrl;

  String? _token;

  // Set token for authenticated requests
  void setToken(String? token) {
    _token = token;
  }

  // Headers for API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Sales API methods
  Future<List<Sale>> getSales() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesData = data['data'];

        // Handle case where data might be empty object instead of empty array
        if (salesData == null || salesData is! List) {
          return [];
        }

        return salesData.map((json) => Sale.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales: $e');
    }
  }

  Future<Sale> createSale(Sale sale) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sales'),
        headers: _headers,
        body: json.encode(sale.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Sale.fromJson(data['data']);
      } else {
        throw Exception('Failed to create sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating sale: $e');
    }
  }

  Future<Sale> updateSale(String id, Sale sale) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sales/$id'),
        headers: _headers,
        body: json.encode(sale.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Sale.fromJson(data['data']);
      } else {
        throw Exception('Failed to update sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating sale: $e');
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sales/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting sale: $e');
    }
  }

  // Expenses API methods
  Future<List<Expense>> getExpenses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final expensesData = data['data'];

        // Handle case where data might be empty object instead of empty array
        if (expensesData == null || expensesData is! List) {
          return [];
        }

        return expensesData.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: _headers,
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Expense.fromJson(data['data']);
      } else {
        throw Exception('Failed to create expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating expense: $e');
    }
  }

  Future<Expense> updateExpense(String id, Expense expense) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: _headers,
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Expense.fromJson(data['data']);
      } else {
        throw Exception('Failed to update expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting expense: $e');
    }
  }

  // Dashboard data
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/overview'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception(
            'Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Authentication methods
  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final authResponse = AuthResponse.fromJson(data['data']);
          _token = authResponse.token;
          return authResponse;
        } else {
          throw Exception(data['message'] ?? 'Registration failed');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(
            data['message'] ?? 'Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  Future<AuthResponse> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: json.encode({
          'login': login,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final authResponse = AuthResponse.fromJson(data['data']);
          _token = authResponse.token;
          return authResponse;
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(
            data['message'] ?? 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: _headers,
      );
      _token = null;
    } catch (e) {
      throw Exception('Error during logout: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Failed to send reset code');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error sending password reset code: $e');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error resetting password: $e');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']);
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // ===== SUPPLIERS API METHODS =====
  Future<List<Supplier>> getSuppliers({bool? active}) async {
    try {
      String url = '$baseUrl/suppliers';
      if (active != null) {
        url += '?active=$active';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suppliersData = data['data'];

        if (suppliersData == null || suppliersData is! List) {
          return [];
        }

        return suppliersData.map((json) => Supplier.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load suppliers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suppliers: $e');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/suppliers'),
        headers: _headers,
        body: json.encode(supplier.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data['data']);
      } else {
        throw Exception('Failed to create supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating supplier: $e');
    }
  }

  Future<Supplier> getSupplier(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data['data']);
      } else {
        throw Exception('Failed to get supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching supplier: $e');
    }
  }

  Future<Supplier> updateSupplier(int id, Supplier supplier) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
        body: json.encode(supplier.toJsonForUpdate()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Supplier.fromJson(data['data']);
      } else {
        throw Exception('Failed to update supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating supplier: $e');
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/suppliers/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete supplier: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting supplier: $e');
    }
  }

  // ===== PROFILE API METHODS =====
  Future<User> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']);
      } else {
        throw Exception('Failed to get profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<User> updateProfile(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
        body: json.encode(user.toJsonForUpdate()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['data']);
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/avatar'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });

      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        imageFile.path,
      ));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['data']['avatar'] ?? '';
      } else {
        throw Exception('Failed to upload avatar: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  // ===== SETTINGS API METHODS =====
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to get settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching settings: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: _headers,
        body: json.encode(settings),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to update settings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating settings: $e');
    }
  }

  // ===== PASSWORD & ACCOUNT API METHODS =====
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: _headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ??
            'Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: _headers,
        body: json.encode({'password': password}),
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete account');
      }
      _token = null;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error deleting account: $e');
    }
  }

  // ===== EXPORT API METHODS =====
  Future<Map<String, dynamic>> exportData({
    required String startDate,
    required String endDate,
    required bool includeSales,
    required bool includeExpenses,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/export-data'),
        headers: _headers,
        body: json.encode({
          'start_date': startDate,
          'end_date': endDate,
          'include_sales': includeSales,
          'include_expenses': includeExpenses,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Failed to export data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error exporting data: $e');
    }
  }

  // ===== ADVANCED DASHBOARD API METHODS =====
  Future<Map<String, dynamic>> getUnpaidCommissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/unpaid-commissions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final commissionsData = data['data'];

        if (commissionsData == null) {
          return {
            'has_unpaid': false,
            'total_unpaid': 0.0,
            'unpaid_commissions': [],
          };
        }

        return {
          'has_unpaid': commissionsData['has_unpaid'] ?? false,
          'total_unpaid': (commissionsData['total_unpaid'] ?? 0.0).toDouble(),
          'unpaid_commissions': commissionsData['unpaid_commissions'] ?? [],
        };
      } else {
        throw Exception(
            'Failed to load unpaid commissions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching unpaid commissions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory({
    int? month,
    int? year,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/dashboard/history';
      List<String> params = [];

      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (type != null) params.add('type=$type');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final historyData = data['data'];

        if (historyData == null || historyData is! List) {
          return [];
        }

        return List<Map<String, dynamic>>.from(historyData);
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats({int? year}) async {
    try {
      String url = '$baseUrl/dashboard/monthly-stats';
      if (year != null) {
        url += '?year=$year';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final statsData = data['data'];

        if (statsData == null || statsData is! List) {
          return [];
        }

        return List<Map<String, dynamic>>.from(statsData);
      } else {
        throw Exception('Failed to load monthly stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching monthly stats: $e');
    }
  }

  // ===== ENHANCED SALES & EXPENSES WITH FILTERING =====
  Future<List<Sale>> getSalesWithFilters({
    int? month,
    int? year,
    int? supplierId,
    bool? commissionPaid,
    String? startDate,
    String? endDate,
    int? perPage,
  }) async {
    try {
      List<String> params = [];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (supplierId != null) params.add('supplier_id=$supplierId');
      if (commissionPaid != null) params.add('commission_paid=$commissionPaid');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      if (perPage != null) params.add('per_page=$perPage');

      String url = '$baseUrl/sales';
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final salesData = data['data'];

        if (salesData == null || salesData is! List) {
          return [];
        }

        return salesData.map((json) => Sale.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales: $e');
    }
  }

  Future<List<Expense>> getExpensesWithFilters({
    int? month,
    int? year,
    String? startDate,
    String? endDate,
    int? perPage,
  }) async {
    try {
      List<String> params = [];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');
      if (perPage != null) params.add('per_page=$perPage');

      String url = '$baseUrl/expenses';
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final expensesData = data['data'];

        if (expensesData == null || expensesData is! List) {
          return [];
        }

        return expensesData.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load expenses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching expenses: $e');
    }
  }

  Future<Sale> markCommissionPaid(String saleId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/sales/$saleId/mark-commission-paid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Sale.fromJson(data['data']);
      } else {
        throw Exception(
            'Failed to mark commission as paid: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking commission as paid: $e');
    }
  }

  // ===== ENHANCED DASHBOARD OVERVIEW =====
  Future<Map<String, dynamic>> getDashboardOverview({
    int? month,
    int? year,
  }) async {
    try {
      List<String> params = [];
      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');

      String url = '$baseUrl/dashboard/overview';
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception(
            'Failed to load dashboard overview: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dashboard overview: $e');
    }
  }
}
