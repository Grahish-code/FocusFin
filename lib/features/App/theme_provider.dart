// ════════════════════════════════════════════════════════════════
//  lib/core/theme/theme_provider.dart
//  Riverpod 2.0 provider for theme switching + SharedPreferences
// ════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Key used for SharedPreferences ────────────────────────────
const _kThemeKey = 'app_theme_mode';

// ── Provider ──────────────────────────────────────────────────
/// Exposes the current [ThemeMode] and lets any widget toggle it.
///
/// Usage (read):
///   final themeMode = ref.watch(themeModeProvider);
///
/// Usage (toggle):
///   ref.read(themeModeProvider.notifier).toggle();
///   ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Start the async load, but return a default synchronous state immediately
    _loadSaved();
    return ThemeMode.dark;
  }

  // Load persisted preference on startup
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);

    if (saved == 'light') {
      state = ThemeMode.light;
    } else if (saved == 'system') {
      state = ThemeMode.system;
    } else if (saved == 'dark') {
      state = ThemeMode.dark;
    }
  }

  // Persist whenever mode changes
  Future<void> _save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }

  /// Toggle between light and dark.
  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    _save(next);
  }

  /// Set a specific mode.
  void setMode(ThemeMode mode) {
    state = mode;
    _save(mode);
  }

  bool get isDark => state == ThemeMode.dark;
}

// ════════════════════════════════════════════════════════════════
//  HOW TO WIRE IN main.dart
// ════════════════════════════════════════════════════════════════
//
//  import 'package:focus_fin/core/theme/app_theme.dart';
//  import 'package:focus_fin/core/theme/theme_provider.dart';
//
//  void main() async {
//    WidgetsFlutterBinding.ensureInitialized();
//    runApp(const ProviderScope(child: FocusFinApp()));
//  }
//
//  class FocusFinApp extends ConsumerWidget {
//    const FocusFinApp({super.key});
//
//    @override
//    Widget build(BuildContext context, WidgetRef ref) {
//      final themeMode = ref.watch(themeModeProvider);
//
//      return MaterialApp(
//        title: 'FocusFin',
//        theme:      AppTheme.light,
//        darkTheme:  AppTheme.dark,
//        themeMode:  themeMode,
//        // ... routes, home, etc.
//      );
//    }
//  }

// ════════════════════════════════════════════════════════════════
//  THEME TOGGLE BUTTON  —  drop anywhere in your UI
// ════════════════════════════════════════════════════════════════
//
//  Notice that the UI code doesn't actually need to change for Riverpod 2!
//  ref.watch() and ref.read(provider.notifier) work exactly the same way.

class AppThemeToggle extends ConsumerWidget {
  const AppThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return GestureDetector(
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 56,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isDark
              ? const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: isDark ? null : const Color(0xFFD0CEC8),
          boxShadow: isDark
              ? [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 14,
              color: isDark
                  ? const Color(0xFF7C3AED)
                  : const Color(0xFFF59E0B),
            ),
          ),
        ),
      ),
    );
  }
}