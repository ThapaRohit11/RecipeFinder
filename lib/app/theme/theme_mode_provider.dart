import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:recipe_finder/core/services/storage/user_session_service.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

final shakeThemeSensorProvider = StateNotifierProvider<ShakeThemeSensorNotifier, bool>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ShakeThemeSensorNotifier(prefs);
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
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final effectiveMode = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    state = effectiveMode;
    final value = effectiveMode == ThemeMode.dark ? 'dark' : 'light';
    await _prefs.setString(_themeKey, value);
  }

  Future<void> toggle() async {
    await setDarkMode(state != ThemeMode.dark);
  }
}

class ShakeThemeSensorNotifier extends StateNotifier<bool> {
  static const String _shakeSensorKey = 'shake_theme_sensor_enabled';

  final dynamic _prefs;

  ShakeThemeSensorNotifier(this._prefs) : super(_loadState(_prefs));

  static bool _loadState(dynamic prefs) {
    return prefs.getBool(_shakeSensorKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_shakeSensorKey, enabled);
  }
}
