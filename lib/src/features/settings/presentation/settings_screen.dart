import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import 'clinic_branches_page.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';

import 'subpages/clinic_details_page.dart';
import 'subpages/staff_permissions_page.dart';
import 'subpages/theme_settings_page.dart';
import 'subpages/services_config_page.dart';
import 'subpages/whatsapp_automation_page.dart';
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
            const SettingsSectionHeader(title: 'البيانات الشخصية والعيادة'),
            SettingsTile(
              icon: Icons.local_hospital_outlined,
              title: 'بيانات العيادة والدكتور',
              subtitle: 'تعديل اسم الطبيب، واسم المركز الطبي',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClinicDetailsPage()),
                );
              },
            ),
            if (isDoctor)
              SettingsTile(
                icon: Icons.badge_outlined,
                title: 'مشاركة كود الدعوة والصلاحيات',
                subtitle: 'إرسال رابط التسجيل للسكرتيرة وضبط الصلاحيات',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StaffPermissionsPage()),
                  );
                },
              ),
            if (user.isOwner)
              SettingsTile(
                icon: Icons.store_mall_directory_outlined,
                title: 'إدارة فروع العيادة',
                subtitle: 'إضافة وتعديل فروع المركز والعيادات الفرعية',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClinicBranchesPage()),
                  );
                },
              ),
            SettingsTile(
              icon: Icons.swap_horiz_rounded,
              title: 'التبديل بين العيادات والفروع',
              subtitle: 'التنقل الفوري بين عياداتك وفروعها المسجلة',
              onTap: () {
                ClinicSwitcherButton.showSwitcherModal(context, ref);
              },
            ),
            const SizedBox(height: AppSpace.lg),

            // ─── القسم الثاني: إدارة الأسعار والخدمات ───
            const SettingsSectionHeader(title: 'الخدمات الطبية والأسعار'),
            SettingsTile(
              icon: Icons.medical_services_outlined,
              title: 'إدارة الكشوفات والخدمات',
              subtitle: 'ضبط أسعار الكشوفات والخدمات الإضافية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServicesConfigPage()),
                );
              },
            ),
            const SizedBox(height: AppSpace.lg),

            // ─── القسم الثالث: الربط والأتمتة ───
            const SettingsSectionHeader(title: 'الربط والأتمتة'),
            SettingsTile(
              icon: Icons.chat_outlined,
              title: 'إعدادات الواتساب والأتمتة',
              subtitle: 'ربط رقم العيادة وتعديل قوالب الرسائل التلقائية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WhatsAppAutomationPage()),
                );
              },
            ),
            const SizedBox(height: AppSpace.lg),

            // ─── القسم الرابع: المظهر والنظام ───
            const SettingsSectionHeader(title: 'تخصيص النظام'),
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'مظهر التطبيق (Theme)',
              subtitle: currentTheme == ThemeMode.light
                  ? 'الوضع الفاتح (النهاري)'
                  : currentTheme == ThemeMode.dark
                      ? 'الوضع الداكن (الليلي)'
                      : 'تلقائي (حسب النظام)',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
                );
              },
            ),
            const SizedBox(height: AppSpace.lg),

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
                title: 'الخروج من العيادة',
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