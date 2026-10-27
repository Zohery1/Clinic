import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/theme/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'مظهر التطبيق',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: ThemeMode.light,
              title: 'الوضع النهاري الفاتح',
              icon: Icons.light_mode_outlined,
              isSelected: currentTheme == ThemeMode.light,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: ThemeMode.dark,
              title: 'الوضع الليلي الداكن',
              icon: Icons.dark_mode_outlined,
              isSelected: currentTheme == ThemeMode.dark,
            ),
            _buildThemeOption(
              context: context,
              ref: ref,
              mode: ThemeMode.system,
              title: 'تلقائي (حسب إعدادات الهاتف/النظام)',
              icon: Icons.settings_brightness_outlined,
              isSelected: currentTheme == ThemeMode.system,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderSubtle(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
            leading: Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary(context),
            ),
            title: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 14,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary(context),
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                : null,
          ),
        ),
      ),
    );
  }
}
