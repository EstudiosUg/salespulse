import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'theme_provider.dart';

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthNotifier(this._apiService, this._prefs)
      : super(AuthState(isLoading: true)) {
    _loadSavedAuth();
  }

  Future<void> _loadSavedAuth() async {
    final token = _prefs.getString(_tokenKey);
    final userData = _prefs.getString(_userKey);

    if (token != null && userData != null) {
      _apiService.setToken(token);
      try {
        // Verify token is still valid by getting current user
        final user = await _apiService.getCurrentUser();
        state = AuthState(
          user: user,
          token: token,
          isAuthenticated: true,
          isLoading: false,
        );
      } catch (e) {
        // Token is invalid, clear saved data
        await _clearAuth();
      }
    } else {
      // No saved auth, just set loading to false
      state = AuthState(isLoading: false);
    }
  }

  Future<void> login(String login, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final authResponse = await _apiService.login(
        login: login,
        password: password,
      );

      await _prefs.setString(_tokenKey, authResponse.token);
      await _prefs.setString(_userKey, authResponse.user.toJson().toString());

      state = AuthState(
        user: authResponse.user,
        token: authResponse.token,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      // Don't auto-login, user should sign in with credentials
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }
    await _clearAuth();
  }

  Future<void> _clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    _apiService.setToken(null);
    state = AuthState(isLoading: false);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final apiService = ApiService();
  return AuthNotifier(apiService, prefs);
});
