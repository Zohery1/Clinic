import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('مظهر التطبيق')),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
          },
          leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
              : null,
        ),
      ),
    );
  }
}
