import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/routing/routing.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import 'widgets/user_profile_header.dart';
import 'widgets/clinic_subscription_card.dart';
import 'widgets/settings_tile.dart';
import 'widgets/settings_dialogs.dart';

/// شاشة الإعدادات الرئيسية
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: Center(
          child: Text(
            'يرجى تسجيل الدخول أولاً',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary(context),
            ),
          ),
        ),
      );
    }

    final isDoctor = user.role == UserRole.doctor;
    final currentTheme = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              children: [
            // ─── بطاقة الملف الشخصي المختصر ───
            UserProfileHeader(user: user),
            const SizedBox(height: AppSpace.lg),

            // ─── بطاقة حالة اشتراك العيادة ───
            ClinicSubscriptionCard(user: user),
            const SizedBox(height: AppSpace.xxl),

            // ─── القسم الأول: البيانات والملفات ───
            const SettingsSectionHeader(title: 'بيانات العيادة والطبيب'),
            SettingsCardGroup(
              children: [
                SettingsTile(
                  icon: Icons.local_hospital_outlined,
                  title: 'بيانات العيادة والطبيب',
                  subtitle: 'تعديل اسم الطبيب، التخصص، وبيانات المركز',
                  onTap: () => AppNavigation.toClinicDetails(context),
                ),
                if (isDoctor)
                  SettingsTile(
                    icon: Icons.badge_outlined,
                    title: 'طاقم العمل والصلاحيات',
                    subtitle: 'دعوة طاقم العمل وتحديد الصلاحيات',
                    onTap: () => AppNavigation.toStaffPermissions(context),
                  ),
                if (user.isOwner)
                  SettingsTile(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'فروع العيادة',
                    subtitle: 'إضافة وتعديل بيانات الفروع',
                    onTap: () => AppNavigation.toClinicBranches(context),
                  ),
                SettingsTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'التبديل بين الفروع والعيادات',
                  subtitle: 'التنقل السريع بين الفروع المسجلة',
                  onTap: () {
                    ClinicSwitcherButton.showSwitcherModal(context, ref);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            // ─── القسم الثاني: إدارة الأسعار والخدمات ───
            const SettingsSectionHeader(title: 'الخدمات الطبية والأسعار'),
            SettingsCardGroup(
              children: [
                SettingsTile(
                  icon: Icons.medical_services_outlined,
                  title: 'قائمة الخدمات والأسعار',
                  subtitle: 'تحديد أسعار الكشوفات والخدمات الطبية',
                  onTap: () => AppNavigation.toServicesConfig(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            // ─── القسم الثالث: الربط والأتمتة ───
            const SettingsSectionHeader(title: 'الربط والأتمتة'),
            SettingsCardGroup(
              children: [
                SettingsTile(
                  icon: Icons.chat_outlined,
                  title: 'إشعارات الواتساب',
                  subtitle: 'ربط الحساب وتخصيص رسائل التذكير التلقائية',
                  onTap: () => AppNavigation.toWhatsAppAutomation(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            // ─── القسم الرابع: المظهر والنظام ───
            const SettingsSectionHeader(title: 'المظهر والعرض'),
            SettingsCardGroup(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'مظهر التطبيق',
                  subtitle: currentTheme == ThemeMode.light
                      ? 'الوضع الفاتح'
                      : currentTheme == ThemeMode.dark
                          ? 'الوضع الداكن'
                          : 'تلقائي (حسب النظام)',
                  onTap: () => AppNavigation.toThemeSettings(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),

            // ─── أزرار الحساب والخروج ───
            SettingsActionCard(
              title: 'تسجيل الخروج',
              icon: Icons.logout_rounded,
              color: AppColors.danger,
              onTap: () => SettingsDialogs.showLogoutDialog(context, ref),
            ),
            if (!user.isOwner) ...[
              const SizedBox(height: AppSpace.md),
              SettingsActionCard(
                title: 'مغادرة العيادة',
                icon: Icons.no_accounts_outlined,
                color: AppColors.danger,
                onTap: () => SettingsDialogs.showLeaveClinicDialog(context, ref),
              ),
            ],

            const SizedBox(height: AppSpace.xxxxl),
            Center(
              child: Text(
                'عيادتي — الإصدار 1.1.0',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted(context),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  ),
);
}
}