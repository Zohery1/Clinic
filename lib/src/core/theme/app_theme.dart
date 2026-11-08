import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_spacing.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/shadows.dart';
import '../ui/tokens/spacing.dart';
import '../ui/tokens/typography.dart';

export '../constants/app_spacing.dart';
export '../ui/tokens/colors.dart';
export '../ui/tokens/motion.dart';
export '../ui/tokens/spacing.dart';

/// Calm Clinical Command Center theme.
///
/// One sapphire accent, hairline structure, quiet elevation. Component themes
/// are defined once here so every screen inherits the same discipline instead
/// of re-declaring buttons and inputs locally.
class AppTheme {
  AppTheme._();

  static const Color primary = AppColors.primary;
  static const Color primaryLight = AppColors.primarySubtle;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color onPrimary = AppColors.onPrimary;

  static const Color background = AppColors.lightCanvas;
  static const Color surface = AppColors.lightSurface;
  static const Color surfaceDim = AppColors.lightSubtle;
  static const Color border = AppColors.lightBorderSubtle;

  static const Color textPrimary = AppColors.lightTextPrimary;
  static const Color textSecondary = AppColors.lightTextSecondary;
  static const Color textHint = AppColors.lightTextMuted;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.danger;
  static const Color completed = AppColors.completed;
  static const Color info = AppColors.info;

  static const Color darkBorder = AppColors.darkBorder;

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: AppColors.borderSubtle(context), width: 1),
      boxShadow: AppShadows.sm(context),
    );
  }

  static BoxDecoration cardDecorationFlat(BuildContext context) {
    return BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: AppColors.borderSubtle(context), width: 1),
    );
  }

  static BoxDecoration clinicalBentoDecoration(
    BuildContext context, {
    Color? accentGlow,
    bool isHighlighted = false,
    double radius = AppRadii.lg,
  }) {
    return BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isHighlighted
            ? (accentGlow ?? AppColors.accent(context))
            : AppColors.borderSubtle(context),
        width: isHighlighted ? 1.5 : 1.0,
      ),
      boxShadow: isHighlighted ? AppShadows.md(context) : AppShadows.sm(context),
    );
  }

  static BoxDecoration statusDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.full),
      );

  static const List<Color> doctorPalette = AppColors.doctorPalette;

  static Color doctorColor(String? doctorId) => AppColors.doctorColor(doctorId);

  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  // ── Shared component shapes ────────────────────────────────────────────────
  static const BorderRadius _controlRadius =
      BorderRadius.all(Radius.circular(AppRadii.radiusSm));
  static const BorderRadius _cardRadius =
      BorderRadius.all(Radius.circular(AppRadii.radiusMd));
  static const BorderRadius _dialogRadius =
      BorderRadius.all(Radius.circular(AppRadii.radiusLg));

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkAccent : AppColors.primary;
    final onAccent = isDark ? const Color(0xFF06101F) : AppColors.onPrimary;
    final canvas =
        isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final panel = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final subtle = isDark ? AppColors.darkSubtle : AppColors.lightSubtle;
    final line =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final lineStrong = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final ink =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final inkSoft =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inkMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final danger = isDark ? AppColors.dangerBright : AppColors.danger;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer:
          isDark ? const Color(0xFF1B3A6B) : AppColors.primarySubtle,
      onPrimaryContainer:
          isDark ? const Color(0xFFD6E4FF) : AppColors.primaryInk,
      secondary: isDark ? AppColors.darkAccent : AppColors.primary,
      onSecondary: onAccent,
      secondaryContainer:
          isDark ? AppColors.darkSubtle : AppColors.lightSubtle,
      onSecondaryContainer: ink,
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: danger,
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF43181A) : AppColors.dangerSubtle,
      onErrorContainer:
          isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D),
      surface: panel,
      onSurface: ink,
      onSurfaceVariant: inkSoft,
      surfaceContainerLowest: isDark ? AppColors.darkCanvas : Colors.white,
      surfaceContainerLow:
          isDark ? AppColors.darkSunken : AppColors.lightCanvas,
      surfaceContainer: subtle,
      surfaceContainerHigh:
          isDark ? AppColors.darkElevated : const Color(0xFFE9EEF5),
      surfaceContainerHighest:
          isDark ? AppColors.darkSubtle : const Color(0xFFE2E8F0),
      outline: lineStrong,
      outlineVariant: line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : AppColors.primaryInk,
      onInverseSurface: isDark ? AppColors.primaryInk : Colors.white,
      inversePrimary: isDark ? AppColors.primary : AppColors.darkAccent,
    );

    final controlText = GoogleFonts.cairo(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: GoogleFonts.cairo().fontFamily,
      primaryColor: accent,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      colorScheme: scheme,
      textTheme: isDark ? AppTypography.dark : AppTypography.light,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      // ── App bar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: panel,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: AppSpace.xl,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.3,
        ),
        iconTheme: IconThemeData(color: inkSoft, size: 20),
        actionsIconTheme: IconThemeData(color: inkSoft, size: 20),
      ),

      // ── Inputs ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSunken : AppColors.lightSurface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 14),
        labelStyle: GoogleFonts.cairo(
          color: inkSoft,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.cairo(
          color: inkMuted,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        helperStyle: GoogleFonts.cairo(
          color: inkMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: GoogleFonts.cairo(
          color: danger,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
        floatingLabelStyle: GoogleFonts.cairo(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        border: OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: lineStrong, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: lineStrong, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _controlRadius,
          borderSide: BorderSide(color: danger, width: 1.6),
        ),
      ),

      // ── Buttons ────────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: subtle,
          disabledForegroundColor: inkMuted,
          elevation: 0,
          minimumSize: const Size(0, 42),
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: controlText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: subtle,
          disabledForegroundColor: inkMuted,
          elevation: 0,
          minimumSize: const Size(0, 46),
          padding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: AppSpace.xl),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: controlText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: lineStrong, width: 1),
          minimumSize: const Size(0, 42),
          padding:
              const EdgeInsets.symmetric(vertical: 11, horizontal: AppSpace.lg),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: controlText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: inkSoft,
          highlightColor: accent.withValues(alpha: 0.10),
          hoverColor: accent.withValues(alpha: 0.08),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
        ),
      ),

      // ── Cards & containers ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: line, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 0),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: _dialogRadius),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: 24),
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.35,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: inkSoft,
          height: 1.6,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: lineStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: subtle,
        selectedColor: accent.withValues(alpha: isDark ? 0.24 : 0.12),
        disabledColor: subtle,
        side: BorderSide(color: line, width: 1),
        labelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: inkSoft,
        ),
        secondaryLabelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkAccent : AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        brightness: brightness,
        shape: const StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkSoft,
        textColor: ink,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: inkMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
      ),

      // ── Feedback ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkElevated : AppColors.primaryInk,
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1.5,
        ),
        actionTextColor: isDark ? AppColors.darkAccent : const Color(0xFFBFD3FF),
        shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
        insetPadding: const EdgeInsets.all(AppSpace.lg),
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.primaryInk,
          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
        ),
        textStyle: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 450),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          side: BorderSide(color: line, width: 1),
        ),
        textStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: subtle,
        circularTrackColor: subtle,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(999),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged)) {
            return inkMuted.withValues(alpha: 0.65);
          }
          return inkMuted.withValues(alpha: 0.32);
        }),
        crossAxisMargin: 2,
        mainAxisMargin: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? onAccent
              : (isDark ? AppColors.gray400 : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : lineStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(onAccent),
        side: BorderSide(color: lineStrong, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.radiusXs),
        ),
        visualDensity: VisualDensity.compact,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : lineStrong,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: inkMuted,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: line,
        labelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
      ),
    );
  }
}
