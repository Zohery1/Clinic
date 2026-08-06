import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/join_clinic_screen.dart';
import '../../auth/presentation/top_up_subscription_screen.dart';
import '../../../../main.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../reports/data/reports_repository.dart';
import '../../appointments/domain/appointment_type_model.dart';
import '../../appointments/domain/service_model.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../data/whatsapp_service.dart';

class ClinicSubscriptionInfo {
  final DateTime? endDate;
  final String status;
  final String clinicName;

  ClinicSubscriptionInfo({
    this.endDate,
    required this.status,
    required this.clinicName,
  });
}

final clinicSubscriptionProvider = FutureProvider.autoDispose<ClinicSubscriptionInfo>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return ClinicSubscriptionInfo(status: 'unknown', clinicName: '');
  }
  try {
    final res = await Supabase.instance.client
        .from('clinics')
        .select('name, subscription_end_date, subscription_status')
        .eq('id', user.clinicId)
        .single();

    final endDateStr = res['subscription_end_date'] as String?;
    final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
    final status = (res['subscription_status'] as String? ?? 'active').toLowerCase();
    final clinicName = res['name'] as String? ?? 'العيادة';

    return ClinicSubscriptionInfo(
      endDate: endDate,
      status: status,
      clinicName: clinicName,
    );
  } catch (_) {
    return ClinicSubscriptionInfo(status: 'active', clinicName: 'العيادة');
  }
});

// مزود كود الدعوة
final inviteCodeProvider = FutureProvider.autoDispose<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return '';
  return ref.watch(authRepositoryProvider).getClinicInviteCode(user.clinicId);
});

// مزود قائمة الموظفين
final staffListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(authRepositoryProvider).getClinicStaff(user.clinicId);
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول أولاً')),
      );
    }

    final isDoctor = user.role == UserRole.doctor;
    final currentTheme = ref.watch(themeModeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: null,
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── بطاقة الملف الشخصي المختصرة ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(context),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.trim().isEmpty
                            ? 'ع'
                            : user.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDoctor ? AppTheme.primaryLight : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDoctor ? 'طبيب' : 'سكرتارية',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDoctor ? AppTheme.primary : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── بطاقة حالة اشتراك العيادة ───
            _buildSubscriptionCard(context, ref, user),
            const SizedBox(height: 24),

            // ─── القسم الأول: البيانات والملفات ───
            _buildSectionHeader(context, 'البيانات الشخصية والعيادة'),
            _buildSettingTile(
              context: context,
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
              _buildSettingTile(
                context: context,
                icon: Icons.badge_outlined,
                title: 'مشاركة كود الدعوة والصلاحيات',
                subtitle: 'إرسال رابط التسجيل للسكرتيرة وضبط الصلاحيات',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StaffPermissionsPage()),
                  );
                },
              ),
            const SizedBox(height: 16),

            // ─── القسم الثاني: إدارة الأسعار والخدمات ───
            _buildSectionHeader(context, 'الخدمات الطبية والأسعار'),
            _buildSettingTile(
              context: context,
              icon: Icons.medical_services_outlined,
              title: 'إدارة الكشوفات والخدمات',
              subtitle: 'ضبط أسعار الكشوفات والخدمات الإضافية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServicesConfigPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // ─── القسم الثالث: الربط والأتمتة ───
            _buildSectionHeader(context, 'الربط والأتمتة'),
            _buildSettingTile(
              context: context,
              icon: Icons.chat_outlined,
              title: 'إعدادات الواتساب والأتمتة',
              subtitle: 'ربط رقم العيادة وتعديل قوالب الرسائل التلقائية',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WhatsAppAutomationPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // ─── القسم الرابع: المظهر والنظام ───
            _buildSectionHeader(context, 'تخصيص النظام'),
            _buildSettingTile(
              context: context,
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
            const SizedBox(height: 24),

            // ─── أزرار الحساب والخروج ───
            _buildActionCard(
              context: context,
              title: 'تسجيل الخروج',
              icon: Icons.logout_rounded,
              color: AppTheme.error,
              onTap: () => _showLogoutDialog(context, ref),
            ),
            if (!isDoctor) ...[
              const SizedBox(height: 12),
              _buildActionCard(
                context: context,
                title: 'الخروج من العيادة والمسح',
                icon: Icons.no_accounts_outlined,
                color: AppTheme.error,
                onTap: () => _showLeaveClinicDialog(context, ref),
              ),
            ],

            const SizedBox(height: 40),
            Center(
              child: Text(
                'عيادتي — الإصدار 1.1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _formatSubscriptionRemaining(DateTime? endDate, String status) {
    if (status == 'suspended' || status == 'expired') return 'انتهى الاشتراك';
    if (endDate == null) return 'غير محدد';
    final diff = endDate.difference(DateTime.now());
    if (diff.isNegative) return 'انتهى الاشتراك';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    if (days > 0 && hours > 0) return 'باقي $days يوم و $hours ساعة';
    if (days > 0) return 'باقي $days يوم';
    if (hours > 0 && minutes > 0) return 'باقي $hours ساعة و $minutes دقيقة';
    if (hours > 0) return 'باقي $hours ساعة';
    if (minutes > 0) return 'باقي $minutes دقيقة';
    return 'أقل من دقيقة';
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref, UserModel user) {
    final subAsync = ref.watch(clinicSubscriptionProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: subAsync.when(
        data: (info) {
          final remainingStr = _formatSubscriptionRemaining(info.endDate, info.status);
          final isExpiringSoon = info.endDate != null &&
              info.endDate!.isAfter(DateTime.now()) &&
              info.endDate!.difference(DateTime.now()).inHours <= 48;
          final isExpired = info.status == 'expired' ||
              (info.endDate != null && info.endDate!.isBefore(DateTime.now()));

          final badgeColor = isExpired
              ? AppTheme.error
              : isExpiringSoon
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF16A34A);

          final badgeBg = isExpired
              ? const Color(0xFFFEE2E2)
              : isExpiringSoon
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFDCFCE7);

          final badgeText = isExpired
              ? 'منتهي'
              : isExpiringSoon
                  ? 'ينتهي قريباً'
                  : 'نشط';

          final formattedDate = info.endDate != null
              ? DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(info.endDate!)
              : 'غير محدد';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'اشتراك العيادة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوقت المتبقي:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingStr,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isExpired || isExpiringSoon
                                ? const Color(0xFFEA580C)
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (info.endDate != null) ...[
                    Container(
                      height: 30,
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاريخ الانتهاء:',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final inviteCode = ref.read(inviteCodeProvider).value ?? '';
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
                            child: TopUpSubscriptionScreen(
                              clinicName: info.clinicName,
                              inviteCode: inviteCode,
                              clinicId: user.clinicId,
                              onRefresh: () {
                                Navigator.of(ctx).pop();
                                ref.invalidate(clinicSubscriptionProvider);
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: Text(
                    'تجديد الاشتراك / شحن الرصيد',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const Text('تعذر تحميل بيانات الاشتراك'),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: Theme.of(context).hintColor),
      ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: Theme.of(context).hintColor),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: const Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('خروج', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveClinicDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'الخروج من العيادة والمسح',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: const Text(
            'تحذير: هذا الإجراء سيقوم بفصل حسابك عن هذه العيادة نهائياً ومسح ملفك الشخصي منها. ستحتاج إلى كود دعوة جديد من عيادة أخرى للانضمام مجدداً. هل أنت متأكد؟',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  // إلغاء ربط المساعد بالعيادة كلياً
                  await Supabase.instance.client.from('users').update({
                    'clinic_id': null,
                    'is_active': true,
                    'can_delete_appointments': false,
                    'can_view_reports': false,
                    'can_edit_services': false,
                    'can_view_medical_history': false,
                    'can_edit_medical_notes': false,
                  }).eq('id', user.id);

                  final updatedUser = await ref.read(authRepositoryProvider).getUserProfile(user.id);
                  ref.read(currentUserProvider.notifier).state = updatedUser;

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => JoinClinicScreen(
                          userName: user.fullName,
                          onRefresh: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthGate()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
              child: const Text('نعم، الخروج والمسح', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ─── 1. صفحة بيانات العيادة والدكتور ───
// ============================================================================
class ClinicDetailsPage extends ConsumerStatefulWidget {
  const ClinicDetailsPage({super.key});

  @override
  ConsumerState<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends ConsumerState<ClinicDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _doctorNameController.text = user.fullName;
      _loadClinicName(user.clinicId);
    }
  }

  void _loadClinicName(String clinicId) async {
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('name')
          .eq('id', clinicId)
          .single();
      _clinicNameController.text = res['name'] as String;
    } catch (_) {}
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        // تحديث اسم الطبيب
        await Supabase.instance.client
            .from('users')
            .update({'full_name': _doctorNameController.text.trim()})
            .eq('id', user.id);

        // تحديث اسم العيادة (للطبيب فقط)
        if (user.role == UserRole.doctor) {
          await Supabase.instance.client
              .from('clinics')
              .update({'name': _clinicNameController.text.trim()})
              .eq('id', user.clinicId);
        }

        // تحديث بروفايل المستخدم محلياً
        final updatedUser = await ref.read(authRepositoryProvider).getUserProfile(user.id);
        ref.read(currentUserProvider.notifier).state = updatedUser;

        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(duration: Duration(seconds: 2), content: Text('تم حفظ البيانات بنجاح'), backgroundColor: AppTheme.success),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(seconds: 2), content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('بيانات العيادة والدكتور')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctorNameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'اسم الطبيب / المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clinicNameController,
                  enabled: user?.role == UserRole.doctor,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'اسم العيادة / المركز الطبي',
                    prefixIcon: const Icon(Icons.business_rounded),
                    helperText: user?.role == UserRole.secretary
                        ? 'تنبيه: السكرتير لا يمكنه تغيير اسم العيادة'
                        : null,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال اسم العيادة' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ البيانات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ─── 2. صفحة مشاركة كود الدعوة والصلاحيات ───
// ============================================================================
class StaffPermissionsPage extends ConsumerWidget {
  const StaffPermissionsPage({super.key});

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          dense: true,
          secondary: Icon(icon, size: 20),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteCodeAsync = ref.watch(inviteCodeProvider);
    final staffAsync = ref.watch(staffListProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('كود الدعوة والصلاحيات')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // كود دعوة السكرتارية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.cardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رابط دعوة السكرتارية والمساعدين',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'انسخ الرابط وأرسله للسكرتيرة لتسجيل حسابها والدخول للعيادة تلقائياً',
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface == Colors.white ? AppTheme.surfaceDim : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: inviteCodeAsync.when(
                      data: (code) {
                        String origin = 'https://myclinic-app.web.app';
                        try {
                          if (Uri.base.hasScheme && (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')) {
                            origin = Uri.base.origin;
                          }
                        } catch (_) {}
                        final inviteLink = "$origin/#/register?invite=$code";

                        return Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.share_rounded, size: 14),
                              label: const Text('نسخ رابط التسجيل السريع', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: inviteLink));
                                ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                  const SnackBar(duration: Duration(seconds: 2), 
                                    content: Text('تم نسخ رابط التسجيل المباشر للسكرتيرة!'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (_, __) => const Text('خطأ في تحميل الكود'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // إدارة صلاحيات الفريق
            Text(
              'صلاحيات المساعدين المسجلين بالعيادة',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 8),

            staffAsync.when(
              data: (staffList) {
                final secretaries = staffList.where((s) => s.role == UserRole.secretary).toList();
                if (secretaries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecorationFlat(context),
                    child: Center(
                      child: Text('لا يوجد سكرتارية منضمين لعيادتك حالياً.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                    ),
                  );
                }

                return Column(
                  children: secretaries.map((staff) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecorationFlat(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                    child: Text(
                                      staff.fullName.isNotEmpty ? staff.fullName[0] : '?',
                                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staff.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        staff.isActive ? 'الحساب نشط' : 'الحساب محظور',
                                        style: TextStyle(fontSize: 11, color: staff.isActive ? AppTheme.success : AppTheme.error),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: staff.isActive,
                                onChanged: (val) async {
                                  await ref.read(authRepositoryProvider).updateUserPermissions(
                                        userId: staff.id,
                                        isActive: val,
                                        canDeleteAppointments: staff.canDeleteAppointments,
                                        canViewReports: staff.canViewReports,
                                        canEditServices: staff.canEditServices,
                                        canViewMedicalHistory: staff.canViewMedicalHistory,
                                        canCancelAppointments: staff.canCancelAppointments,
                                      );
                                  ref.invalidate(staffListProvider);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Category 1: المواعيد والحجوزات
                          Text(
                            '🗓️ إدارة المواعيد والحجوزات',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          _buildPermissionTile(
                            title: 'إلغاء المواعيد والاعتذار للمرضى',
                            subtitle: 'تغيير حالة الموعد إلى ملغي وإرسال رسالة الاعتذار',
                            icon: Icons.event_busy_rounded,
                            value: staff.canCancelAppointments,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: staff.canViewReports,
                                            canEditServices: staff.canEditServices,
                                            canViewMedicalHistory: staff.canViewMedicalHistory,
                                            canCancelAppointments: val,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),
                          _buildPermissionTile(
                            title: 'حذف المواعيد نهائياً من النظام',
                            subtitle: 'حذف سجل الحجز تماماً من قاعدة البيانات',
                            icon: Icons.delete_forever_rounded,
                            value: staff.canDeleteAppointments,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: val,
                                            canViewReports: staff.canViewReports,
                                            canEditServices: staff.canEditServices,
                                            canViewMedicalHistory: staff.canViewMedicalHistory,
                                            canCancelAppointments: staff.canCancelAppointments,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),

                          const SizedBox(height: 12),
                          // Category 2: الخدمات والملفات الطبية
                          Text(
                            '🩺 الخدمات والملفات الطبية',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          _buildPermissionTile(
                            title: 'إضافة وتعديل الخدمات والأسعار',
                            subtitle: 'إنشاء خدمات جديدة وتغيير تسعيرة الكشوفات والخدمات',
                            icon: Icons.medical_services_outlined,
                            value: staff.canEditServices,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: staff.canViewReports,
                                            canEditServices: val,
                                            canViewMedicalHistory: staff.canViewMedicalHistory,
                                            canCancelAppointments: staff.canCancelAppointments,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),
                          _buildPermissionTile(
                            title: 'الاطلاع على الروشتات والتاريخ الطبي',
                            subtitle: 'عرض التقرير الطبي والتشخيص والروشتات السابقة للمريض',
                            icon: Icons.description_outlined,
                            value: staff.canViewMedicalHistory,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: staff.canViewReports,
                                            canEditServices: staff.canEditServices,
                                            canViewMedicalHistory: val,
                                            canEditMedicalNotes: staff.canEditMedicalNotes,
                                            canCancelAppointments: staff.canCancelAppointments,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),
                          _buildPermissionTile(
                            title: 'كتابة وتعديل التقرير والتشخيص الطبي',
                            subtitle: 'إدخال وتعديل التقرير والتشخيص والتعليمات الخاصة بالزيارات',
                            icon: Icons.edit_note_rounded,
                            value: staff.canEditMedicalNotes,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: staff.canViewReports,
                                            canEditServices: staff.canEditServices,
                                            canViewMedicalHistory: staff.canViewMedicalHistory,
                                            canEditMedicalNotes: val,
                                            canCancelAppointments: staff.canCancelAppointments,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),

                          const SizedBox(height: 12),
                          // Category 3: المالية والتقارير
                          Text(
                            '📊 المالية والتقارير',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 6),
                          _buildPermissionTile(
                            title: 'رؤية التقارير المالية والإيرادات',
                            subtitle: 'الاطلاع على إجمالي دخل العيادة اليومي والشهري',
                            icon: Icons.insights_rounded,
                            value: staff.canViewReports,
                            onChanged: !staff.isActive
                                ? null
                                : (val) async {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: val,
                                            canEditServices: staff.canEditServices,
                                            canViewMedicalHistory: staff.canViewMedicalHistory,
                                            canEditMedicalNotes: staff.canEditMedicalNotes,
                                            canCancelAppointments: staff.canCancelAppointments,
                                          );
                                      ref.invalidate(staffListProvider);
                                  },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
              error: (err, _) => Text('خطأ: $err', style: const TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ─── 3. صفحة المظهر والألوان (Theme Selector) ───
// ============================================================================
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

// ============================================================================
// ─── 4. صفحة إدارة الكشوفات والخدمات والأسعار ───
// ============================================================================
class ServicesConfigPage extends ConsumerStatefulWidget {
  const ServicesConfigPage({super.key});

  @override
  ConsumerState<ServicesConfigPage> createState() => _ServicesConfigPageState();
}

class _ServicesConfigPageState extends ConsumerState<ServicesConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    final isDoctor = user.role == UserRole.doctor;
    final canManageServices = isDoctor || user.canEditServices;
    final appointmentTypesAsync = ref.watch(appointmentTypesProvider);
    final servicesAsync = ref.watch(servicesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('أسعار الكشوفات والخدمات'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'أسعار الكشوفات'),
              Tab(text: 'الخدمات الطبية الإضافية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentTypesTab(appointmentTypesAsync, isDoctor),
            _buildServicesTab(servicesAsync, isDoctor),
          ],
        ),
        floatingActionButton: canManageServices
            ? FloatingActionButton(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded),
                onPressed: () {
                  if (_tabController.index == 0) {
                    _showAddAppointmentTypeDialog(context, user.clinicId);
                  } else {
                    _showAddServiceDialog(context, user.clinicId);
                  }
                },
              )
            : null,
      ),
    );
  }

  // الكشوفات
  Widget _buildAppointmentTypesTab(AsyncValue<List<AppointmentTypeModel>> asyncData, bool canManageServices) {
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('لا توجد أسعار كشوفات مضافة بعد.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final type = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecorationFlat(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${type.price.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (canManageServices)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showEditAppointmentTypeDialog(context, type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                          onPressed: () => _showDeleteAppointmentTypeConfirm(context, type),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
    );
  }

  // الخدمات
  Widget _buildServicesTab(AsyncValue<List<ServiceModel>> asyncData, bool canManageServices) {
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(child: Text('لا توجد خدمات مضافة بعد.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final service = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecorationFlat(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${service.price.toStringAsFixed(0)} ج.م', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  if (canManageServices)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showEditServiceDialog(context, service),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                          onPressed: () => _showDeleteServiceConfirm(context, service),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('خطأ: $err')),
    );
  }

  // ─── الحوارات المنبثقة للعمليات ───

  void _showAddAppointmentTypeDialog(BuildContext context, String clinicId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.medical_services_outlined,
      title: 'إضافة نوع كشف جديد',
      subtitle: 'سيُضاف للقائمة المتاحة عند حجز المواعيد',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الكشف',
              hint: 'مثال: كشف استشاري، متابعة',
              prefixIcon: Icons.badge_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الكشف' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'سعر الكشف (ج.م)',
              hint: '0',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        _SaveButton(
          label: 'حفظ',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final name = nameCtrl.text.trim();
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            await ref.read(reportsRepositoryProvider).addAppointmentType(
                  clinicId: clinicId, name: name, price: price);
            _invalidateTypes();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showEditAppointmentTypeDialog(BuildContext context, dynamic type) {
    final nameCtrl = TextEditingController(text: type.name);
    final priceCtrl = TextEditingController(text: type.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.edit_outlined,
      title: 'تعديل نوع الكشف',
      subtitle: type.name,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الكشف',
              prefixIcon: Icons.badge_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'السعر (ج.م)',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        _SaveButton(
          label: 'تعديل',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).updateAppointmentType(
                  id: type.id,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateTypes();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showDeleteAppointmentTypeConfirm(BuildContext context, dynamic type) {
    ClinicDialog.confirm(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'حذف نوع الكشف',
      description: 'هل أنت متأكد من حذف نوع الكشف "${type.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(reportsRepositoryProvider).deleteAppointmentType(type.id);
        _invalidateTypes();
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, String clinicId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.role == UserRole.secretary && !currentUser.canEditServices) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ليس لديك صلاحية لإضافة أو تعديل الخدمات والأسعار. يرجى مراجعة الطبيب.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.add_circle_outline_rounded,
      title: 'إضافة خدمة طبية جديدة',
      subtitle: 'مثال: رسم قلب، غيار جروح، حقنة',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الخدمة',
              hint: 'مثال: رسم قلب ECG',
              prefixIcon: Icons.medical_services_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الخدمة' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'سعر الخدمة (ج.م)',
              hint: '0',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        _SaveButton(
          label: 'حفظ',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).addService(
                  clinicId: clinicId,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateServices();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showEditServiceDialog(BuildContext context, dynamic service) {
    final nameCtrl = TextEditingController(text: service.name);
    final priceCtrl = TextEditingController(text: service.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.edit_outlined,
      title: 'تعديل الخدمة الطبية',
      subtitle: service.name,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الخدمة',
              prefixIcon: Icons.medical_services_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'السعر (ج.م)',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        _SaveButton(
          label: 'تعديل',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).updateService(
                  id: service.id,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateServices();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showDeleteServiceConfirm(BuildContext context, dynamic service) {
    ClinicDialog.confirm(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'حذف الخدمة الطبية',
      description: 'هل أنت متأكد من حذف الخدمة "${service.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(reportsRepositoryProvider).deleteService(service.id);
        _invalidateServices();
      },
    );
  }

  void _invalidateTypes() {
    ref.invalidate(appointmentTypesProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(monthRevenueProvider);
    ref.invalidate(weeklyRevenueProvider);
    ref.invalidate(dailyStatsProvider);
    ref.invalidate(monthlyStatsProvider);
  }

  void _invalidateServices() {
    ref.invalidate(servicesProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(monthRevenueProvider);
    ref.invalidate(weeklyRevenueProvider);
    ref.invalidate(dailyStatsProvider);
    ref.invalidate(monthlyStatsProvider);
  }
}

// زر حفظ مع loading state — مستخدم في حوارات الإعدادات
class _SaveButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;

  const _SaveButton({required this.label, required this.onPressed});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } catch (e) {
                if (context.mounted) {
                  ClinicToast.showError(context, 'خطأ: $e');
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      child: _loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ============================================================================
// ─── 5. صفحة إعدادات الواتساب والأتمتة ───
// ============================================================================
class WhatsAppAutomationPage extends ConsumerStatefulWidget {
  const WhatsAppAutomationPage({super.key});

  @override
  ConsumerState<WhatsAppAutomationPage> createState() => _WhatsAppAutomationPageState();
}

class _WhatsAppAutomationPageState extends ConsumerState<WhatsAppAutomationPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _whatsappPhoneController = TextEditingController();
  final _whatsappInstanceNameController = TextEditingController();
  final _bookingTemplateController = TextEditingController();
  final _reminderTemplateController = TextEditingController();
  final _cancellationTemplateController = TextEditingController();
  
  bool _whatsappEnabled = false;
  bool _sendBookingMessage = true;
  bool _sendReminderMessage = true;
  bool _sendCancellationMessage = true;
  String _whatsappStatus = 'disconnected';
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select()
          .eq('id', user.clinicId)
          .single();

      setState(() {
        _whatsappEnabled = res['whatsapp_enabled'] as bool? ?? false;
        _whatsappPhoneController.text = res['whatsapp_phone'] as String? ?? '';
        _whatsappInstanceNameController.text = res['whatsapp_instance_name'] as String? ?? '';
        _whatsappStatus = res['whatsapp_status'] as String? ?? 'disconnected';
        _sendBookingMessage = res['send_booking_message'] as bool? ?? true;
        _sendReminderMessage = res['send_reminder_message'] as bool? ?? true;
        _sendCancellationMessage = res['send_cancellation_message'] as bool? ?? true;
        _bookingTemplateController.text = res['booking_message_template'] as String? ?? '';
        _reminderTemplateController.text = res['reminder_message_template'] as String? ?? '';
        _cancellationTemplateController.text = res['cancellation_message_template'] as String? ??
            'عزيزي المريض [patient_name]، نعتذر عن إلغاء موعدك في العيادة بتاريخ [date] لظروف طارئة بالعيادة. نتمنى لكم دوام الصحة والعافية.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _whatsappPhoneController.dispose();
    _whatsappInstanceNameController.dispose();
    _bookingTemplateController.dispose();
    _reminderTemplateController.dispose();
    _cancellationTemplateController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        await Supabase.instance.client
            .from('clinics')
            .update({
              'whatsapp_enabled': _whatsappEnabled,
              'whatsapp_phone': _whatsappPhoneController.text.trim(),
              'whatsapp_status': _whatsappStatus,
              'send_booking_message': _sendBookingMessage,
              'send_reminder_message': _sendReminderMessage,
              'send_cancellation_message': _sendCancellationMessage,
              'booking_message_template': _bookingTemplateController.text.trim(),
              'reminder_message_template': _reminderTemplateController.text.trim(),
              'cancellation_message_template': _cancellationTemplateController.text.trim(),
            })
            .eq('id', user.clinicId);

        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(duration: Duration(seconds: 2), content: Text('تم حفظ إعدادات الأتمتة بنجاح'), backgroundColor: AppTheme.success),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(seconds: 2), content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _insertTag(TextEditingController controller, String tag) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, tag);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + tag.length);
    } else {
      controller.text = text + tag;
    }
  }

  void _simulateQrScan() {
    final user = ref.read(currentUserProvider);
    final instanceName = user != null ? 'clinic_${user.clinicId.replaceAll('-', '_').substring(0, 8)}' : 'clinic_default';
    Timer? pollTimer;
    bool isConnectedSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        int selectedMethodTab = 0;
        String? qrBase64;
        String? pairingCode;
        bool isLoadingQr = true;
        String? qrError;
        String activeInstanceName = instanceName;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void checkStatus() async {
              if (isConnectedSuccess) return;
              try {
                final statusRes = await ref.read(whatsappServiceProvider).checkEvolutionStatus(activeInstanceName!);
                if (statusRes != null && statusRes['connectionStatus'] == 'open') {
                  isConnectedSuccess = true;
                  pollTimer?.cancel();

                  String connectedPhone = _whatsappPhoneController.text;
                  if (statusRes['phone'] != null) {
                    String p = statusRes['phone'].toString();
                    if (p.startsWith('201') && p.length == 12) {
                      connectedPhone = '01${p.substring(3)}';
                    } else {
                      connectedPhone = p;
                    }
                  }

                  if (user != null) {
                    await Supabase.instance.client
                        .from('clinics')
                        .update({
                          'whatsapp_status': 'connected',
                          'whatsapp_enabled': true,
                          'whatsapp_instance_name': activeInstanceName,
                          'whatsapp_phone': connectedPhone,
                        })
                        .eq('id', user.clinicId);
                  }

                  setState(() {
                    _whatsappStatus = 'connected';
                    _whatsappEnabled = true;
                    _whatsappInstanceNameController.text = activeInstanceName!;
                    _whatsappPhoneController.text = connectedPhone;
                  });

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(this.context)..clearSnackBars()..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 3),
                        content: Text(connectedPhone.isNotEmpty
                            ? 'تم ربط حساب الواتساب بنجاح! رقم العيادة: $connectedPhone'
                            : 'تم ربط حساب الواتساب بنجاح وتفعيل الأتمتة'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              } catch (_) {}
            }

            void loadQr() async {
              setDialogState(() {
                isLoadingQr = true;
                qrError = null;
              });

              try {
                final res = await ref.read(whatsappServiceProvider).fetchEvolutionQr(instanceName);

                if (res != null) {
                  final data = res;
                  String? fetchedQr;
                  String? fetchedPairing;

                  if (data['base64'] != null) {
                    fetchedQr = data['base64'] as String;
                  } else if (data['code'] != null) {
                    fetchedQr = data['code'] as String;
                  }

                  if (data['pairingCode'] != null) {
                    fetchedPairing = data['pairingCode'] as String;
                  } else if (data['pairing_code'] != null) {
                    fetchedPairing = data['pairing_code'] as String;
                  }

                  if (data['qrcode'] != null && data['qrcode']['base64'] != null) {
                    fetchedQr = data['qrcode']['base64'] as String;
                  }

                  if (fetchedQr != null || fetchedPairing != null) {
                    setDialogState(() {
                      qrBase64 = fetchedQr;
                      pairingCode = fetchedPairing;
                      isLoadingQr = false;
                    });
                    pollTimer?.cancel();
                    pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => checkStatus());
                  } else {
                    setDialogState(() {
                      isLoadingQr = false;
                      qrError = data['error'] != null ? '${data['error']}' : 'في انتظار تهيئة الجلسة بالبوابة...';
                    });
                  }
                } else {
                  setDialogState(() {
                    isLoadingQr = false;
                    qrError = 'لم يتم الحصول على بيانات الجلسة';
                  });
                }
              } catch (e) {
                setDialogState(() {
                  isLoadingQr = false;
                  qrError = 'خطأ في الاتصال بالبوابة: $e';
                });
              }
            }

            // Load on open once
            if (isLoadingQr && qrBase64 == null && qrError == null) {
              loadQr();
            }

            return PopScope(
              onPopInvokedWithResult: (_, __) => pollTimer?.cancel(),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(
                    'ربط حساب الواتساب الخاص بالعيادة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceDim,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedMethodTab = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selectedMethodTab == 0 ? theme.colorScheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'رمز QR (كمبيوتر)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: selectedMethodTab == 0 ? Colors.white : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => selectedMethodTab = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selectedMethodTab == 1 ? theme.colorScheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'كود رقمي (نفس الموبايل)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: selectedMethodTab == 1 ? Colors.white : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (selectedMethodTab == 0) ...[
                          Text(
                            'امسح الرمز المربع من تطبيق WhatsApp بهاتفك (الأجهزة المرتبطة > ربط جهاز)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 12, color: theme.hintColor),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: 200,
                            height: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                            ),
                            child: isLoadingQr
                                ? const Center(child: CircularProgressIndicator())
                                : (qrBase64 != null && qrBase64!.isNotEmpty)
                                    ? Image.memory(
                                        base64Decode(qrBase64!.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '')),
                                        fit: BoxFit.contain,
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Text(
                                            qrError ?? 'اضغط لإعادة التوليد',
                                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                          IconButton(
                                            onPressed: loadQr,
                                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                          ),
                        ] else ...[
                          Text(
                            'افتح تطبيق WhatsApp من هاتفك (الأجهزة المرتبطة > الربط برقم الهاتف) وادخل الكود التالي:',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 12, color: theme.hintColor),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: isLoadingQr
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(
                                    pairingCode ?? '1234 - 5678',
                                    style: GoogleFonts.cairo(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: loadQr,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              tooltip: 'تحديث الرمز',
                            ),
                            Text(
                              selectedMethodTab == 0 ? 'في انتظار مسح الرمز المربع...' : 'في انتظار إدخال الكود بالهاتف...',
                              style: GoogleFonts.cairo(fontSize: 12, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        pollTimer?.cancel();
                        Navigator.pop(dialogContext);
                      },
                      child: Text('إلغاء', style: GoogleFonts.cairo()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        pollTimer?.cancel();
                        String realInstanceName = instanceName;
                        String connectedPhone = _whatsappPhoneController.text;

                        if (user != null) {
                          try {
                            final clinicRow = await Supabase.instance.client
                                .from('clinics')
                                .select('whatsapp_phone')
                                .eq('id', user.clinicId)
                                .maybeSingle();
                            if (clinicRow != null && clinicRow['whatsapp_phone'] != null) {
                              connectedPhone = clinicRow['whatsapp_phone'] as String;
                            }
                          } catch (_) {}

                          try {
                            final statusRes = await ref.read(whatsappServiceProvider).checkEvolutionStatus(realInstanceName);
                            if (statusRes != null && statusRes['phone'] != null) {
                              String p = statusRes['phone'].toString();
                              if (p.startsWith('201') && p.length == 12) {
                                connectedPhone = '01${p.substring(3)}';
                              } else {
                                connectedPhone = p;
                              }
                            }
                          } catch (_) {}

                          await Supabase.instance.client
                              .from('clinics')
                              .update({
                                'whatsapp_status': 'connected',
                                'whatsapp_enabled': true,
                                'whatsapp_instance_name': realInstanceName,
                                'whatsapp_phone': connectedPhone,
                              })
                              .eq('id', user.clinicId);
                        }

                        setState(() {
                          _whatsappStatus = 'connected';
                          _whatsappEnabled = true;
                          _whatsappInstanceNameController.text = realInstanceName;
                          _whatsappPhoneController.text = connectedPhone;
                        });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context)..clearSnackBars()..showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 3),
                              content: Text(connectedPhone.isNotEmpty
                                  ? 'تم ربط الواتساب بنجاح! رقم العيادة: $connectedPhone'
                                  : 'تم ربط حساب الواتساب بنجاح وتفعيل الأتمتة'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      child: Text('تم المسح والربط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _disconnectWhatsapp() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إلغاء ربط الواتساب'),
          content: const Text('هل أنت متأكد من رغبتك في إلغاء ربط رقم العيادة وتعطيل الإرسال التلقائي؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                setState(() {
                  _whatsappStatus = 'disconnected';
                  _whatsappEnabled = false;
                  _whatsappPhoneController.clear();
                });

                if (user != null) {
                  await Supabase.instance.client
                      .from('clinics')
                      .update({
                        'whatsapp_status': 'disconnected',
                        'whatsapp_enabled': false,
                      })
                      .eq('id', user.clinicId);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 2), 
                      content: Text('تم إلغاء ربط الواتساب بنجاح'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('نعم، إلغاء الربط'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعدادات الواتساب والأتمتة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isConnected = _whatsappStatus == 'connected';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('إعدادات الواتساب والأتمتة'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. كارت حالة الاتصال
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_cell_rounded,
                              color: isConnected ? AppTheme.success : AppTheme.error,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'حالة الاتصال بالبوابة',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isConnected ? AppTheme.success : AppTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isConnected ? 'متصل ومفعّل' : 'غير متصل',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isConnected ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isDoctor)
                        ElevatedButton(
                          onPressed: isConnected ? _disconnectWhatsapp : _simulateQrScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConnected ? theme.colorScheme.error : theme.colorScheme.primary,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isConnected ? 'إلغاء ربط الواتساب' : 'ربط الواتساب الآن (مسح الرمز)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. إعدادات الأتمتة الأساسية
                Text(
                  'أتمتة الرسائل التلقائية',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _whatsappEnabled,
                        onChanged: isConnected && isDoctor
                            ? (val) => setState(() => _whatsappEnabled = val)
                            : null,
                        title: const Text('تفعيل خدمة الواتساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال تنبيهات المواعيد للمرضى عبر الواتساب', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendBookingMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendBookingMessage = val)
                            : null,
                        title: const Text('رسالة تأكيد الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة فورية عند حجز موعد جديد للمريض', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendReminderMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendReminderMessage = val)
                            : null,
                        title: const Text('رسالة تذكير بالموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة تذكير تلقائية قبل موعد الزيارة بـ 24 ساعة', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendCancellationMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendCancellationMessage = val)
                            : null,
                        title: const Text('رسالة اعتذار عند إلغاء الموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة اعتذار تلقائية للمريض عند إلغاء موعده من قِبل العيادة', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),



                // 4. قوالب الرسائل وتخصيصها
                if (_sendBookingMessage) ...[
                  Text(
                    'قالب رسالة تأكيد الحجز',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bookingTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_bookingTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                if (_sendReminderMessage) ...[
                  Text(
                    'قالب رسالة التذكير بالموعد',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reminderTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_reminderTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                if (_sendCancellationMessage) ...[
                  Text(
                    'قالب رسالة الاعتذار عن إلغاء الموعد',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cancellationTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_cancellationTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 20),
                // زر حفظ البيانات
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ إعدادات الأتمتة'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartTagsRow(TextEditingController controller, bool enabled) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTagBadge(controller, '[patient_name]', 'اسم المريض', enabled),
        _buildTagBadge(controller, '[date]', 'التاريخ', enabled),
        _buildTagBadge(controller, '[time]', 'وقت الموعد', enabled),
      ],
    );
  }

  Widget _buildTagBadge(TextEditingController controller, String tag, String label, bool enabled) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? () => _insertTag(controller, tag) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$label $tag',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}


