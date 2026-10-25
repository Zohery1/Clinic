import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../settings_providers.dart';

class StaffPermissionsPage extends ConsumerWidget {
  const StaffPermissionsPage({super.key});

  Widget _buildPermissionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.subtle(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.borderSubtle(context).withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          dense: true,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          secondary: Icon(icon, size: 20, color: AppColors.primary),
          title: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary(context),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
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
    final isDark = AppColors.isDark(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'كود الدعوة والصلاحيات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: [
            // كود دعوة السكرتارية
            Container(
              padding: const EdgeInsets.all(AppSpace.xl),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderSubtle(context),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رابط دعوة السكرتارية والمساعدين',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'انسخ الرابط وأرسله للسكرتيرة لتسجيل حسابها والدخول للعيادة تلقائياً',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.subtle(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderSubtle(context),
                        width: 1.0,
                      ),
                    ),
                    child: inviteCodeAsync.when(
                      data: (code) {
                        String origin = 'https://myclinic-app.web.app';
                        try {
                          if (Uri.base.hasScheme &&
                              (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')) {
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
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: Text(
                                'نسخ الرابط',
                                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: inviteLink));
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      duration: const Duration(seconds: 2),
                                      content: Text(
                                        'تم نسخ رابط التسجيل المباشر للسكرتيرة!',
                                        style: GoogleFonts.cairo(),
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ),
                      error: (_, __) => Center(
                        child: Text(
                          'خطأ في تحميل الكود',
                          style: GoogleFonts.cairo(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            staffAsync.when(
              data: (staffList) {
                final doctors = staffList.where((s) => s.role == UserRole.doctor).toList();
                final secretaries = staffList.where((s) => s.role == UserRole.secretary).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 1. الأطباء بالعيادة ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'أطباء العيادة (${doctors.length})',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (doctors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
                        ),
                        child: Center(
                          child: Text(
                            'لا يوجد أطباء منضمين للعيادة.',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted(context)),
                          ),
                        ),
                      )
                    else
                      ...doctors.map((doc) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
                          ),
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
                                        backgroundColor: isDark
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : AppColors.primarySubtle,
                                        child: const Icon(
                                          Icons.person_pin_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'د. ${doc.fullName}',
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary(context),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: doc.isOwner
                                                      ? (isDark
                                                          ? AppColors.primary.withValues(alpha: 0.15)
                                                          : AppColors.primarySubtle)
                                                      : AppColors.subtle(context),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  doc.isOwner ? 'مدير العيادة (المالك)' : 'طبيب ممارس',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: doc.isOwner
                                                        ? AppColors.primary
                                                        : AppColors.textSecondary(context),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            doc.isActive ? 'الحساب نشط' : 'الحساب محظور',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: doc.isActive ? AppColors.success : AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (!doc.isOwner)
                                    Switch(
                                      value: doc.isActive,
                                      activeTrackColor: AppColors.primary,
                                      activeThumbColor: Colors.white,
                                      onChanged: (val) async {
                                        await ref.read(authRepositoryProvider).updateUserPermissions(
                                              userId: doc.id,
                                              isActive: val,
                                              canDeleteAppointments: doc.canDeleteAppointments,
                                              canViewReports: doc.canViewReports,
                                              canEditServices: doc.canEditServices,
                                              canViewMedicalHistory: doc.canViewMedicalHistory,
                                              canCancelAppointments: doc.canCancelAppointments,
                                            );
                                        ref.invalidate(staffListProvider);
                                      },
                                    ),
                                ],
                              ),
                              if (!doc.isOwner) ...[
                                const SizedBox(height: 12),
                                Divider(height: 1, color: AppColors.borderSubtle(context)),
                                const SizedBox(height: 8),
                                _buildPermissionTile(
                                  context,
                                  title: 'صلاحية رؤية إيرادات وتقارير العيادة العامة',
                                  subtitle: 'تتيح للطبيب الاطلاع على الدخل الإجمالي للعيادة بجانب إيراداته الشخصية',
                                  icon: Icons.insights_rounded,
                                  value: doc.canViewReports,
                                  onChanged: !doc.isActive
                                      ? null
                                      : (val) async {
                                          await ref.read(authRepositoryProvider).updateUserPermissions(
                                                userId: doc.id,
                                                isActive: doc.isActive,
                                                canDeleteAppointments: doc.canDeleteAppointments,
                                                canViewReports: val,
                                                canEditServices: doc.canEditServices,
                                                canViewMedicalHistory: doc.canViewMedicalHistory,
                                                canEditMedicalNotes: doc.canEditMedicalNotes,
                                                canCancelAppointments: doc.canCancelAppointments,
                                              );
                                          ref.invalidate(staffListProvider);
                                        },
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: AppSpace.xxl),

                    // ─── 2. المساعدين والسكرتارية ───
                    Text(
                      'صلاحيات المساعدين والسكرتارية (${secretaries.length})',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (secretaries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
                        ),
                        child: Center(
                          child: Text(
                            'لا يوجد سكرتارية منضمين لعيادتك حالياً.',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted(context)),
                          ),
                        ),
                      )
                    else
                      ...secretaries.map((staff) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: isDark
                                              ? AppColors.primary.withValues(alpha: 0.15)
                                              : AppColors.primarySubtle,
                                          child: Text(
                                            staff.fullName.isNotEmpty ? staff.fullName[0] : '?',
                                            style: GoogleFonts.cairo(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                staff.fullName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary(context),
                                                ),
                                              ),
                                              Text(
                                                staff.isActive ? 'الحساب نشط' : 'الحساب محظور',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: staff.isActive ? AppColors.success : AppColors.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: staff.isActive,
                                    activeTrackColor: AppColors.primary,
                                    activeThumbColor: Colors.white,
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
                              Divider(height: 1, color: AppColors.borderSubtle(context)),
                              const SizedBox(height: 12),

                              // Category 1: المواعيد والحجوزات
                              Text(
                                '🗓️ إدارة المواعيد والحجوزات',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildPermissionTile(
                                context,
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
                                context,
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
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildPermissionTile(
                                context,
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
                                context,
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
                                context,
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
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildPermissionTile(
                                context,
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
                      }),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpace.xl),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'خطأ: $err',
                  style: GoogleFonts.cairo(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
