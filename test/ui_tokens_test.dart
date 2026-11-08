import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_management/src/core/ui/tokens/colors.dart';
import 'package:clinic_management/src/core/ui/tokens/spacing.dart';

void main() {
  group('Clinical Design Tokens - Colors', () {
    test('Primary palette matches authoritative clinical sapphire and deep navy', () {
      expect(AppColors.primary, const Color(0xFF1D4ED8));
      expect(AppColors.primaryDark, const Color(0xFF1E3A8A));
      expect(AppColors.lightCanvas, const Color(0xFFF8FAFC));
      expect(AppColors.darkCanvas, const Color(0xFF090D16));
    });

    test('Semantic status colors are defined and distinct', () {
      expect(AppColors.success, const Color(0xFF059669));
      expect(AppColors.warning, const Color(0xFFD97706));
      expect(AppColors.danger, const Color(0xFFDC2626));
      expect(AppColors.info, const Color(0xFF0284C7));
      expect(AppColors.completed, const Color(0xFF7C3AED));

      // Ensure border tokens exist and are distinct
      expect(AppColors.successBorder, const Color(0xFFA7F3D0));
      expect(AppColors.warningBorder, const Color(0xFFFDE68A));
      expect(AppColors.dangerBorder, const Color(0xFFFECACA));
    });

    test('Doctor palette provides at least 8 distinct clinical badge colors', () {
      expect(AppColors.doctorPalette.length, greaterThanOrEqualTo(8));
      final uniqueColors = AppColors.doctorPalette.toSet();
      expect(uniqueColors.length, AppColors.doctorPalette.length);

      // Deterministic hashing for any doctor ID
      final color1 = AppColors.doctorColor('doc-123');
      final color2 = AppColors.doctorColor('doc-123');
      expect(color1, equals(color2));
      expect(AppColors.doctorPalette.contains(color1), isTrue);

      // Fallback for null or empty ID
      expect(AppColors.doctorColor(null), AppColors.doctorPalette.first);
      expect(AppColors.doctorColor(''), AppColors.doctorPalette.first);
    });

    test('Light mode body text passes WCAG AA contrast against white surface', () {
      // Relative luminance calculation according to WCAG 2.1
      double luminance(Color color) {
        return color.computeLuminance();
      }

      double contrastRatio(Color fg, Color bg) {
        final l1 = luminance(fg);
        final l2 = luminance(bg);
        final lighter = l1 > l2 ? l1 : l2;
        final darker = l1 > l2 ? l2 : l1;
        return (lighter + 0.05) / (darker + 0.05);
      }

      final ratioPrimary = contrastRatio(AppColors.lightTextPrimary, AppColors.lightSurface);
      expect(ratioPrimary, greaterThanOrEqualTo(7.0),
          reason: 'Primary text must exceed AAA normal text contrast (7.0)');

      final ratioSecondary = contrastRatio(AppColors.lightTextSecondary, AppColors.lightSurface);
      expect(ratioSecondary, greaterThanOrEqualTo(4.5),
          reason: 'Secondary text must exceed AA normal text contrast (4.5)');
    });
  });

  group('Clinical Design Tokens - Spacing & Radii', () {
    test('Spacing follows 4-pt clinical grid scale', () {
      expect(AppSpace.xs, 4.0);
      expect(AppSpace.sm, 8.0);
      expect(AppSpace.md, 12.0);
      expect(AppSpace.lg, 16.0);
      expect(AppSpace.xl, 20.0);
      expect(AppSpace.xxl, 24.0);
      expect(AppSpace.xxxl, 32.0);
    });

    test('Radii tokens provide consistent border radius curves', () {
      expect(AppRadii.radiusXs, 4.0);
      expect(AppRadii.radiusSm, 8.0);
      expect(AppRadii.radiusMd, 12.0);
      expect(AppRadii.radiusLg, 16.0);
      expect(AppRadii.radiusXl, 20.0);
      expect(AppRadii.radiusX2l, 24.0);
      expect(AppRadii.radiusFull, 9999.0);
    });
  });
}
