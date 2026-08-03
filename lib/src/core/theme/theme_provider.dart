import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeKey = 'app_theme_mode';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        if (savedTheme == 'dark') {
          state = ThemeMode.dark;
        } else if (savedTheme == 'light') {
          state = ThemeMode.light;
        } else if (savedTheme == 'system') {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeStr = 'light';
      if (mode == ThemeMode.dark) {
        themeStr = 'dark';
      } else if (mode == ThemeMode.system) {
        themeStr = 'system';
      }
      await prefs.setString(_themeKey, themeStr);
    } catch (_) {}
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
