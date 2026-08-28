import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_spacing.dart';

export '../constants/app_spacing.dart';

/// Design Tokens — Calm Medical Clean Color Palette
class AppColors {
  AppColors._();

  // Primary Brand (Calm Medical Clean)
  static const Color primary = Color(0xFF1A73E8);        // Clean Medical Blue
  static const Color primaryLight = Color(0xFFE8F0FE);   // Soft Tint (10-12%)
  static const Color primaryDark = Color(0xFF1557B0);    // Deep Blue
  static const Color onPrimary = Colors.white;

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFF8F9FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDimLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Backgrounds & Surfaces (Dark)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDimDark = Color(0xFF151E2E);
  static const Color borderDark = Color(0xFF334155);

  // Typography Tokens (Light)
  static const Color textPrimaryLight = Color(0xFF1E293B);   // Slate 800
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textHintLight = Color(0xFF94A3B8);      // Slate 400

  // Typography Tokens (Dark)
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);

  // Semantic Status Colors
  static const Color success = Color(0xFF059669);   // Completed / Confirmed (Emerald)
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);   // Waiting / Pending (Amber)
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF1A73E8);      // In Progress / With Doctor (Blue)
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color error = Color(0xFFDC2626);     // Cancelled / Expired (Rose)
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color completed = Color(0xFF7C3AED); // Purple status
  static const Color completedLight = Color(0xFFF5F3FF);

  // Doctor Multi-Avatar Palette
  static const List<Color> doctorPalette = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF059669),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
  ];
}

/// نظام الهوية البصرية — عيادتي
/// Clean Medical SaaS — Light & Dark Theme Configuration
class AppTheme {
  AppTheme._();

  // ─── الألوان الأساسية (Backward Compatible Aliases) ───
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color onPrimary = AppColors.onPrimary;

  // ─── الأسطح والخلفيات ───
  static const Color background = AppColors.backgroundLight;
  static const Color surface = AppColors.surfaceLight;
  static const Color surfaceDim = AppColors.surfaceDimLight;
  static const Color border = AppColors.borderLight;

  // ─── النصوص ───
  static const Color textPrimary = AppColors.textPrimaryLight;
  static const Color textSecondary = AppColors.textSecondaryLight;
  static const Color textHint = AppColors.textHintLight;

  // ─── حالات الموعد ───
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color completed = AppColors.completed;
  static const Color info = AppColors.info;

  static const Color darkBorder = AppColors.borderDark;

  // ─── أدوات مساعدة ───
  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.03),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration cardDecorationFlat(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      ),
    );
  }

  static BoxDecoration statusDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      );

  static const List<Color> doctorPalette = AppColors.doctorPalette;

  static Color doctorColor(String? doctorId) {
    if (doctorId == null || doctorId.isEmpty) {
      return doctorPalette.first;
    }
    final hash = doctorId.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return doctorPalette[hash % doctorPalette.length];
  }

  // ─── الثيم الأساسي الفاتح ───
  static ThemeData get lightTheme {
    final cairoText = GoogleFonts.cairoTextTheme(const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryLight,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryLight,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.onPrimary,
      ),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.primary,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: AppColors.surfaceDimLight,
        error: AppColors.error,
        outline: AppColors.borderLight,
      ),
      textTheme: cairoText,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDimLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textHintLight, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryLight,
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.borderLight),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1, space: 0),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondaryLight,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: AppColors.borderLight,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXs)),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textHintLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
          return AppColors.surfaceDimLight;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primaryLight,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textPrimaryLight;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteTextColor: AppColors.textPrimaryLight,
        hourMinuteColor: AppColors.surfaceDimLight,
        dayPeriodTextColor: AppColors.textPrimaryLight,
        dayPeriodColor: AppColors.surfaceDimLight,
        dialHandColor: AppColors.primary,
        dialTextColor: AppColors.textPrimaryLight,
        dialBackgroundColor: AppColors.surfaceDimLight,
        entryModeIconColor: AppColors.primary,
      ),
    );
  }

  // ─── الثيم الداكن ───
  static ThemeData get darkTheme {
    final cairoText = GoogleFonts.cairoTextTheme(const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimaryDark,
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryDark,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1E3A8A),
        secondary: AppColors.primary,
        surface: AppColors.surfaceDark,
        surfaceContainerHighest: AppColors.surfaceDimDark,
        error: Color(0xFFEF4444),
        outline: AppColors.borderDark,
      ),
      textTheme: cairoText,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDimDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textHintDark, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondaryDark,
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderDark, thickness: 1, space: 0),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        hourMinuteTextColor: Colors.white,
        hourMinuteColor: AppColors.backgroundDark,
        dayPeriodTextColor: Colors.white,
        dayPeriodColor: AppColors.backgroundDark,
        dialHandColor: AppColors.primary,
        dialTextColor: Colors.white,
        dialBackgroundColor: AppColors.backgroundDark,
        entryModeIconColor: AppColors.primary,
      ),
    );
  }
}
