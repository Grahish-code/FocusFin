// lib/core/theme/app_theme.dart
//
// Single source of truth for BOTH light and dark themes.
// All tokens (colours, gradients, shadows, radii, text styles)
// are defined here. Import only this one file everywhere.
//
// Usage:
//   import 'package:your_app/core/theme/app_theme.dart';
//
//   // In MaterialApp:
//   theme:      AppTheme.light,
//   darkTheme:  AppTheme.dark,
//   themeMode:  ref.watch(themeModeProvider),
//
//   // In any widget:
//   final c = context.appColors;   // resolves light or dark at runtime
//   Container(color: c.bg)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
//  COLOURS  —  raw palette (both modes)
// ═══════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Light surfaces ─────────────────────────────────────────────
  static const Color bgLight       = Color(0xFFF4F3EF);
  static const Color surfaceLight  = Colors.white;
  static const Color surface2Light = Color(0xFFEDEBE5);

  // ── Dark surfaces ──────────────────────────────────────────────
  static const Color bgDark        = Color(0xFF0E0E0F);
  static const Color surfaceDark   = Color(0xFF1A1A1D);
  static const Color surface2Dark  = Color(0xFF242428);

  // ── Text — light mode ──────────────────────────────────────────
  static const Color textDarkL  = Color(0xFF111111);
  static const Color textMutedL = Color(0xFF888888);

  // ── Text — dark mode ───────────────────────────────────────────
  static const Color textDarkD  = Color(0xFFF0EEE9);
  static const Color textMutedD = Color(0xFF6E6D72);

  // ── Semantic (same in both modes) ─────────────────────────────
  static const Color emerald = Color(0xFF34D399);
  static const Color rose    = Color(0xFFF87171);
  static const Color amber   = Color(0xFFFBBF24);
  static const Color violet  = Color(0xFFA78BFA);

  // ── Borders ────────────────────────────────────────────────────
  static const Color borderLight  = Color(0xFFE5E3DD);
  static const Color borderDark   = Color(0xFF2C2C31);
  static const Color borderBright = Color(0xFF3D3D44);

  // ── Glass — light mode ─────────────────────────────────────────
  static const Color glassFillL   = Color(0xB8E8E6E0);
  static const Color glassBorderL = Color(0xFFD0CEC8);

  // ── Glass — dark mode ──────────────────────────────────────────
  static const Color glassFillD   = Color(0xCC1E1E22);
  static const Color glassBorderD = Color(0xFF2F2F36);

  // ── Gradient endpoints ─────────────────────────────────────────
  static const Color gradientStart        = Color(0xFF7C3AED);
  static const Color gradientEnd          = Color(0xFF4F46E5);
  static const Color gradientEmeraldStart = Color(0xFF059669);
  static const Color gradientEmeraldEnd   = Color(0xFF0D9488);
  static const Color gradientRoseStart    = Color(0xFFDC2626);
  static const Color gradientRoseEnd      = Color(0xFFDB2777);
  static const Color gradientAmberStart   = Color(0xFFD97706);
  static const Color gradientAmberEnd     = Color(0xFFEA580C);
  static const Color gradientVioletStart  = Color(0xFF7C3AED);
  static const Color gradientVioletEnd    = Color(0xFF6366F1);

  // ── Shimmer (dark-mode glass highlight) ───────────────────────
  static const Color shimmerLight = Color(0x14FFFFFF);
  static const Color shimmerDark  = Color(0x00FFFFFF);
}

// ═══════════════════════════════════════════════════════════════
//  GRADIENTS
// ═══════════════════════════════════════════════════════════════

class AppGradients {
  AppGradients._();

  // Primary CTA — dark mode: violet/indigo glow
  static const LinearGradient primaryButton = LinearGradient(
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Primary CTA — light mode: charcoal
  static const LinearGradient primaryButtonLight = LinearGradient(
    colors: [Color(0xFF2B2B2B), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Hero balance card background (dark mode)
  static const LinearGradient heroCard = LinearGradient(
    colors: [Color(0xFF1E1E28), Color(0xFF14141A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic gradients
  static const LinearGradient emerald = LinearGradient(
    colors: [AppColors.gradientEmeraldStart, AppColors.gradientEmeraldEnd],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient rose = LinearGradient(
    colors: [AppColors.gradientRoseStart, AppColors.gradientRoseEnd],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient amber = LinearGradient(
    colors: [AppColors.gradientAmberStart, AppColors.gradientAmberEnd],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient violet = LinearGradient(
    colors: [AppColors.gradientVioletStart, AppColors.gradientVioletEnd],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Shimmer highlight strip on glass cards (dark mode)
  static const LinearGradient glassShimmer = LinearGradient(
    colors: [AppColors.shimmerLight, AppColors.shimmerDark],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Dynamic chart fill
  static LinearGradient chartFill(Color color) => LinearGradient(
    colors: [color.withOpacity(0.22), color.withOpacity(0.0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ═══════════════════════════════════════════════════════════════
//  SHADOWS
// ═══════════════════════════════════════════════════════════════

class AppShadows {
  AppShadows._();

  // Dark glass card shadow
  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 24, offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.04),
      blurRadius: 0, offset: const Offset(0, -1),
    ),
  ];

  // Light glass card shadow
  static List<BoxShadow> get glassLight => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20, offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.45),
      blurRadius: 0, offset: const Offset(0, -1),
    ),
  ];

  // Violet/indigo glow for CTA buttons (dark mode)
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: AppColors.gradientStart.withOpacity(0.40),
      blurRadius: 20, offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.gradientEnd.withOpacity(0.20),
      blurRadius: 40, offset: const Offset(0, 12),
    ),
  ];

  // Light mode CTA button shadow
  static List<BoxShadow> get elevatedLight => [
    BoxShadow(
      color: const Color(0xFF111111).withOpacity(0.2),
      blurRadius: 10, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get emeraldGlow => [
    BoxShadow(
      color: AppColors.emerald.withOpacity(0.30),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get roseGlow => [
    BoxShadow(
      color: AppColors.rose.withOpacity(0.25),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withOpacity(0.60),
      blurRadius: 32, offset: const Offset(0, 16),
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════════════════════════════

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle appTitle = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.5,
  );
  static const TextStyle screenTitle = TextStyle(
    fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1.0,
  );
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500,
  );
  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.4,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
  static const TextStyle amountLarge = TextStyle(
    fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1,
  );
  static const TextStyle amountMedium = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static const TextStyle amountSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5,
  );
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
  );
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700,
  );
}

// ═══════════════════════════════════════════════════════════════
//  BORDER RADIUS
// ═══════════════════════════════════════════════════════════════

class AppRadius {
  AppRadius._();
  static const double xs  = 8.0;
  static const double sm  = 12.0;
  static const double md  = 16.0;
  static const double lg  = 20.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
}

// ═══════════════════════════════════════════════════════════════
//  INPUT DECORATION
// ═══════════════════════════════════════════════════════════════

class AppInputDecoration {
  AppInputDecoration._();

  static InputDecoration field(String label, IconData icon,
      {required bool isDark}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: isDark ? AppColors.textMutedD : AppColors.textMutedL),
      prefixIcon: Icon(icon,
          color: isDark ? AppColors.textMutedD : AppColors.textMutedL),
      filled: true,
      fillColor: isDark ? AppColors.surface2Dark : AppColors.surface2Light,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.gradientStart.withOpacity(0.8)
              : AppColors.textDarkL,
          width: 2,
        ),
      ),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RUNTIME COLOUR RESOLVER  —  AppColorScheme + context extension
// ═══════════════════════════════════════════════════════════════
//
//  Widgets should read colours via:
//    final c = context.appColors;
//    c.bg, c.surface, c.textDark, c.emerald, c.border ...
//
//  This automatically returns the right values for whichever
//  ThemeMode is active — no if/else needed in widget code.

class AppColorScheme {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color textDark;
  final Color textMuted;
  final Color border;
  final Color glassFill;
  final Color glassBorder;
  final bool isDark;

  // Semantic colours are the same in both modes
  Color get emerald => AppColors.emerald;
  Color get rose    => AppColors.rose;
  Color get amber   => AppColors.amber;
  Color get violet  => AppColors.violet;

  const AppColorScheme({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.textDark,
    required this.textMuted,
    required this.border,
    required this.glassFill,
    required this.glassBorder,
    required this.isDark,
  });

  static const AppColorScheme dark = AppColorScheme(
    bg:          AppColors.bgDark,
    surface:     AppColors.surfaceDark,
    surface2:    AppColors.surface2Dark,
    textDark:    AppColors.textDarkD,
    textMuted:   AppColors.textMutedD,
    border:      AppColors.borderDark,
    glassFill:   AppColors.glassFillD,
    glassBorder: AppColors.glassBorderD,
    isDark:      true,
  );

  static const AppColorScheme light = AppColorScheme(
    bg:          AppColors.bgLight,
    surface:     AppColors.surfaceLight,
    surface2:    AppColors.surface2Light,
    textDark:    AppColors.textDarkL,
    textMuted:   AppColors.textMutedL,
    border:      AppColors.borderLight,
    glassFill:   AppColors.glassFillL,
    glassBorder: AppColors.glassBorderL,
    isDark:      false,
  );
}

// Build-context helper — resolves correct scheme automatically
extension AppThemeX on BuildContext {
  AppColorScheme get appColors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColorScheme.dark
          : AppColorScheme.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Convenience: returns the right gradient for CTAs
  LinearGradient get ctaGradient => isDarkMode
      ? AppGradients.primaryButton
      : AppGradients.primaryButtonLight;

  // Convenience: returns the right shadow for CTAs
  List<BoxShadow> get ctaShadow =>
      isDarkMode ? AppShadows.primaryGlow : AppShadows.elevatedLight;

  // Convenience: returns the right glass card shadow
  List<BoxShadow> get glassShadow =>
      isDarkMode ? AppShadows.glass : AppShadows.glassLight;
}

// ═══════════════════════════════════════════════════════════════
//  MATERIAL THEMES
// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData get dark  => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? AppColorScheme.dark : AppColorScheme.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,

      colorScheme: ColorScheme(
        brightness: brightness,
        background: c.bg,
        surface:    c.surface,
        primary:    isDark ? AppColors.gradientStart : AppColors.textDarkL,
        secondary:  AppColors.emerald,
        error:      AppColors.rose,
        onBackground: c.textDark,
        onSurface:    c.textDark,
        onPrimary:    Colors.white,
        onSecondary:  Colors.white,
        onError:      Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: brightness,
          statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: c.textDark, letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: c.textDark),
      ),

      textTheme: TextTheme(
        displayLarge:   AppTextStyles.appTitle.copyWith(color: c.textDark),
        displayMedium:  AppTextStyles.screenTitle.copyWith(color: c.textDark),
        headlineMedium: AppTextStyles.sectionHeading.copyWith(color: c.textDark),
        titleLarge:     AppTextStyles.cardTitle.copyWith(color: c.textDark),
        bodyLarge:      AppTextStyles.bodyLarge.copyWith(color: c.textMuted),
        bodyMedium:     AppTextStyles.bodyRegular.copyWith(color: c.textDark),
        bodySmall:      AppTextStyles.bodySmall.copyWith(color: c.textMuted),
        labelSmall:     AppTextStyles.sectionLabel.copyWith(color: c.textMuted),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface2,
        labelStyle: TextStyle(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.gradientStart.withOpacity(0.8)
                : AppColors.textDarkL,
            width: 2,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: c.surface2,
          foregroundColor: c.textDark,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: c.border),
          ),
          textStyle: AppTextStyles.buttonPrimary,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          backgroundColor: c.surface,
          foregroundColor: c.textDark,
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          splashFactory: NoSplash.splashFactory,
          foregroundColor: c.textMuted,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: c.border, thickness: 1, space: 1,
      ),

      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
      ),
    );
  }
}