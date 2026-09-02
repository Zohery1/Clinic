import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';
import '../ui/tokens/shadows.dart';
import '../ui/tokens/typography.dart';
import '../constants/app_spacing.dart';

export '../ui/tokens/colors.dart';
export '../ui/tokens/spacing.dart';
export '../ui/tokens/motion.dart';
export '../constants/app_spacing.dart';

/// Theme builder. Public API (`AppTheme.cardDecoration`, `statusDecoration`,
/// `doctorColor`, `doctorPalette`) is preserved while the underlying color
/// sources are the new token system.
class AppTheme {
  AppTheme._();

  // Brand
  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primarySubtle;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color onPrimary = AppColors.onPrimary;

  // Surfaces
  static const Color background = AppColors.lightCanvas;
  static const Color surface = AppColors.lightSurface;
  static const Color surfaceDim = AppColors.lightSubtle;
  static const Color border = AppColors.lightBorderSubtle;

  // Text
  static const Color textPrimary = AppColors.lightTextPrimary;
  static const Color textSecondary = AppColors.lightTextSecondary;
  static const Color textHint = AppColors.lightTextMuted;

  // Status
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color completed = AppColors.completed;
  static const Color info = AppColors.info;

  static const Color darkBorder = AppColors.darkBorder;

  // Decorations
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadii.radiusMd),
      border: Border.all(
        color: AppColors.borderSubtle(context),
        width: 1,
      ),
      boxShadow: AppShadows.sm(context),
    );
  }

  static BoxDecoration cardDecorationFlat(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadii.radiusMd),
      border: Border.all(
        color: AppColors.borderSubtle(context),
        width: 1,
      ),
    );
  }

  static BoxDecoration statusDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.radiusFull),
      );

  static const List<Color> doctorPalette = AppColors.doctorPalette;

  static Color doctorColor(String? doctorId) => AppColors.doctorColor(doctorId);

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primarySubtle,
        secondary: AppColors.primary,
        surface: AppColors.lightSurface,
        surfaceContainerHighest: AppColors.lightSubtle,
        error: AppColors.danger,
        outline: AppColors.lightBorderSubtle,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
      ),
      textTheme: AppTypography.light,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpace.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightTextSecondary,
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorderSubtle),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpace.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          side: const BorderSide(color: AppColors.lightBorderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorderSubtle, thickness: 1, space: 0),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusSm)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusLg)),
        elevation: 8,
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: AppColors.lightBorderSubtle,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusXs)),
        side: const BorderSide(color: AppColors.lightBorderSubtle, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.lightTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primarySubtle;
          return AppColors.lightSubtle;
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusMd)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.primarySubtle,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.lightTextPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: Colors.white,
        hourMinuteTextColor: AppColors.lightTextPrimary,
        hourMinuteColor: AppColors.lightSubtle,
        dayPeriodTextColor: AppColors.lightTextPrimary,
        dayPeriodColor: AppColors.lightSubtle,
        dialHandColor: AppColors.primary,
        dialTextColor: AppColors.lightTextPrimary,
        dialBackgroundColor: AppColors.lightSubtle,
        entryModeIconColor: AppColors.primary,
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkCanvas,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.primary,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSubtle,
        error: AppColors.dangerBright,
        outline: AppColors.darkBorder,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
      ),
      textTheme: AppTypography.dark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSubtle,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.dangerBright, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
          borderSide: const BorderSide(color: AppColors.dangerBright, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: AppSpace.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkTextSecondary,
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpace.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusSm)),
          textStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1, space: 0),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.darkSurface,
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
        backgroundColor: AppColors.darkSurface,
        hourMinuteTextColor: Colors.white,
        hourMinuteColor: AppColors.darkCanvas,
        dayPeriodTextColor: Colors.white,
        dayPeriodColor: AppColors.darkCanvas,
        dialHandColor: AppColors.primary,
        dialTextColor: Colors.white,
        dialBackgroundColor: AppColors.darkCanvas,
        entryModeIconColor: AppColors.primary,
      ),
    );
  }
}
