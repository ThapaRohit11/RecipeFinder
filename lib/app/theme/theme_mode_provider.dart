import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:recipe_finder/core/services/storage/user_session_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  final dynamic _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(dynamic prefs) {
    final value = prefs.getString(_themeKey);
    if (value == 'dark') {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString(_themeKey, isDark ? 'dark' : 'light');
  }

  Future<void> toggle() async {
    await setDarkMode(state != ThemeMode.dark);
  }
}
