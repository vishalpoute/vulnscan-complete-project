import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

/// Notifier for theme mode
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    // TODO: Load from local storage
    state = ThemeMode.system;
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    // TODO: Save to local storage
  }

  void setLight() {
    state = ThemeMode.light;
    // TODO: Save to local storage
  }

  void setDark() {
    state = ThemeMode.dark;
    // TODO: Save to local storage
  }

  void setSystem() {
    state = ThemeMode.system;
    // TODO: Save to local storage
  }
}

/// Provider for theme mode
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  return ThemeNotifier();
});
