import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../reports/presentation/reports_controller.dart';
import '../../reports/data/reports_repository.dart';
import '../../appointments/domain/appointment_type_model.dart';
import '../../appointments/domain/service_model.dart';
import '../../../core/widgets/clinic_dialog.dart';

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
        appBar: AppBar(
          title: const Text('الإعدادات العامة'),
          elevation: 0,
        ),
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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

            // ─── القسم الثالث: المظهر والنظام ───
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
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecorationFlat(context),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: Theme.of(context).hintColor),
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
    return Container(
      decoration: AppTheme.cardDecorationFlat(context),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
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
                  await Supabase.instance.client
                      .from('users')
                      .delete()
                      .eq('id', user.id);

                  await ref.read(authRepositoryProvider).signOut();
                  ref.read(currentUserProvider.notifier).state = null;

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ البيانات بنجاح'), backgroundColor: AppTheme.success),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.error),
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

  Widget _buildPermissionTile(String title, bool value, ValueChanged<bool?>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
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
                    style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
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
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
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
                                  Text(
                                    staff.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                                      );
                                  ref.invalidate(staffListProvider);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildPermissionTile(
                            'السماح بحذف المواعيد والحجوزات',
                            staff.canDeleteAppointments,
                            !staff.isActive
                                ? null
                                : (val) async {
                                    if (val != null) {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: val,
                                            canViewReports: staff.canViewReports,
                                          );
                                      ref.invalidate(staffListProvider);
                                    }
                                  },
                          ),
                          _buildPermissionTile(
                            'السماح برؤية التقارير المالية والتحليلات',
                            staff.canViewReports,
                            !staff.isActive
                                ? null
                                : (val) async {
                                    if (val != null) {
                                      await ref.read(authRepositoryProvider).updateUserPermissions(
                                            userId: staff.id,
                                            isActive: staff.isActive,
                                            canDeleteAppointments: staff.canDeleteAppointments,
                                            canViewReports: val,
                                          );
                                      ref.invalidate(staffListProvider);
                                    }
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          ref.read(themeModeProvider.notifier).state = mode;
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
        floatingActionButton: isDoctor
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
  Widget _buildAppointmentTypesTab(AsyncValue<List<AppointmentTypeModel>> asyncData, bool isDoctor) {
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
                  if (isDoctor)
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
  Widget _buildServicesTab(AsyncValue<List<ServiceModel>> asyncData, bool isDoctor) {
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
                  if (isDoctor)
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
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


