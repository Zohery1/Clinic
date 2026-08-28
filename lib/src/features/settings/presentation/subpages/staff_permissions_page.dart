import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';
import '../settings_providers.dart';

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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 14),
                                  label: const Text('نسخ الرابط', style: TextStyle(fontSize: 12)),
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
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (doctors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecorationFlat(context),
                        child: Center(
                          child: Text('لا يوجد أطباء منضمين للعيادة.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                        ),
                      )
                    else
                      ...doctors.map((doc) {
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
                                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                        child: Icon(Icons.person_pin_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'د. ${doc.fullName}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: doc.isOwner 
                                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                                                      : Colors.grey.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  doc.isOwner ? 'مدير العيادة (المالك)' : 'طبيب ممارس',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: doc.isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).hintColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            doc.isActive ? 'الحساب نشط' : 'الحساب محظور',
                                            style: TextStyle(fontSize: 11, color: doc.isActive ? AppTheme.success : AppTheme.error),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (!doc.isOwner)
                                    Switch(
                                      value: doc.isActive,
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
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                _buildPermissionTile(
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

                    const SizedBox(height: 24),

                    // ─── 2. المساعدين والسكرتارية ───
                    Text(
                      'صلاحيات المساعدين والسكرتارية (${secretaries.length})',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),

                    if (secretaries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecorationFlat(context),
                        child: Center(
                          child: Text('لا يوجد سكرتارية منضمين لعيادتك حالياً.', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                        ),
                      )
                    else
                      ...secretaries.map((staff) {
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
                  }),
                ],
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
