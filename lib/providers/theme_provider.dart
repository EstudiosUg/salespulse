import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const String _key = 'isDarkMode';

  ThemeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  void toggleTheme() {
    state = !state;
    _prefs.setBool(_key, state);
  }

  void setTheme(bool isDark) {
    state = isDark;
    _prefs.setBool(_key, isDark);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Should be overridden in main');
});

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});
