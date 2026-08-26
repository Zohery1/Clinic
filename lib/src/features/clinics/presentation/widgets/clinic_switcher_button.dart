import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../clinics_controller.dart';
import '../../domain/clinic_summary_model.dart';
import 'create_clinic_dialog.dart';
import 'join_clinic_dialog.dart';

class ClinicSwitcherButton extends ConsumerWidget {
  final bool isCompact;

  const ClinicSwitcherButton({
    super.key,
    this.isCompact = false,
  });

  static void showSwitcherModal(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
            margin: const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final clinicsList = ref.watch(userClinicsProvider);
                final activeClinicSummary = ref.watch(activeClinicSummaryProvider);
                final currentUserId = ref.watch(currentUserProvider);
                final activeClinicId = currentUserId?.activeClinicId ?? currentUserId?.clinicId;
                final activeBranchId = currentUserId?.activeBranchId ?? activeClinicSummary?.mainBranch?.id;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Modal Header ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'التبديل بين العيادات والفروع',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                                Text(
                                  'اضغط على أي عيادة أو أي فرع للدخول والعمل عليه فوراً',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // ─── Clinics List ───
                    Flexible(
                      child: clinicsList.when(
                        data: (clinics) {
                          if (clinics.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.business_outlined, size: 48, color: theme.hintColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد عيادات مسجلة بحسابك حالياً',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            shrinkWrap: true,
                            itemCount: clinics.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final clinic = clinics[idx];
                              final isCurrentClinic = clinic.clinicId == activeClinicId;

                              return _buildClinicCard(
                                context: context,
                                ref: ref,
                                clinic: clinic,
                                isCurrentClinic: isCurrentClinic,
                                activeBranchId: activeBranchId,
                                bottomSheetContext: ctx,
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  'تعذر تحميل العيادات',
                                  style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () => ref.invalidate(userClinicsProvider),
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // ─── Bottom Actions ───
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                showDialog(
                                  context: context,
                                  builder: (_) => const JoinClinicDialog(),
                                );
                              },
                              icon: const Icon(Icons.group_add_rounded, size: 18),
                              label: Text(
                                'انضمام بكود دعوة',
                                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                showDialog(
                                  context: context,
                                  builder: (_) => const CreateClinicDialog(),
                                );
                              },
                              icon: const Icon(Icons.add_business_rounded, size: 18),
                              label: Text(
                                'إنشاء عيادة جديدة',
                                style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Widget _buildClinicCard({
    required BuildContext context,
    required WidgetRef ref,
    required ClinicSummaryModel clinic,
    required bool isCurrentClinic,
    required String? activeBranchId,
    required BuildContext bottomSheetContext,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isCurrentClinic
            ? primaryColor.withValues(alpha: 0.05)
            : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentClinic ? primaryColor : AppTheme.darkBorder.withValues(alpha: 0.25),
          width: isCurrentClinic ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Clinic Info Row ───
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () async {
              final defaultBranchId = clinic.mainBranch?.id;
              final success = await ref
                  .read(clinicsControllerProvider.notifier)
                  .switchActiveClinic(clinic.clinicId, branchId: defaultBranchId);
              if (success && bottomSheetContext.mounted) {
                Navigator.of(bottomSheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم الانتقال إلى عيادة: ${clinic.clinicName}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.green.shade700,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isCurrentClinic
                        ? primaryColor
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: isCurrentClinic ? Colors.white : theme.textTheme.bodyLarge?.color,
                    child: Icon(
                      clinic.isOwner ? Icons.local_hospital_rounded : Icons.medical_services_rounded,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                clinic.clinicName,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildRoleBadge(clinic.role, clinic.isOwner),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              clinic.branches.isEmpty
                                  ? 'الفرع الرئيسي'
                                  : '${clinic.branches.length} ${clinic.branches.length == 1 ? "فرع" : "فروع"}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(clinic.subscriptionStatus, clinic.isActive),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentClinic)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'النشطة حالياً',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: theme.hintColor.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          ),

          // ─── Branches Section (ALWAYS visible for ALL clinics) ───
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.share_location_rounded,
                          size: 14,
                          color: isCurrentClinic ? primaryColor : theme.hintColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'الفروع التابعة (اضغط لدخول أي فرع مباشرة):',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // عرض بطاقات/أزرار الفروع
                if (clinic.branches.isEmpty) ...[
                  // فرع افتراضي إذا لم تكن هناك فروع مخصصة
                  _buildBranchChip(
                    context: context,
                    ref: ref,
                    clinic: clinic,
                    branchId: null,
                    branchName: 'الفرع الرئيسي (افتراضي)',
                    isMain: true,
                    isCurrentBranch: isCurrentClinic,
                    bottomSheetContext: bottomSheetContext,
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: clinic.branches.map((branch) {
                      final isCurrentBranch = isCurrentClinic &&
                          (activeBranchId == branch.id || (activeBranchId == null && branch.isMain));

                      return _buildBranchChip(
                        context: context,
                        ref: ref,
                        clinic: clinic,
                        branchId: branch.id,
                        branchName: branch.name,
                        isMain: branch.isMain,
                        isCurrentBranch: isCurrentBranch,
                        bottomSheetContext: bottomSheetContext,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة فرع قابلة للضغط المباشر
  static Widget _buildBranchChip({
    required BuildContext context,
    required WidgetRef ref,
    required ClinicSummaryModel clinic,
    required String? branchId,
    required String branchName,
    required bool isMain,
    required bool isCurrentBranch,
    required BuildContext bottomSheetContext,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final success = await ref
              .read(clinicsControllerProvider.notifier)
              .switchActiveClinic(clinic.clinicId, branchId: branchId);
          if (success && bottomSheetContext.mounted) {
            Navigator.of(bottomSheetContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم الانتقال إلى: ${clinic.clinicName} ($branchName)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isCurrentBranch
                ? primaryColor
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrentBranch
                  ? primaryColor
                  : theme.dividerColor.withValues(alpha: 0.35),
              width: isCurrentBranch ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCurrentBranch ? Icons.check_circle_rounded : Icons.location_on_outlined,
                size: 14,
                color: isCurrentBranch ? Colors.white : theme.hintColor,
              ),
              const SizedBox(width: 5),
              Text(
                branchName,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: isCurrentBranch ? FontWeight.bold : FontWeight.w600,
                  color: isCurrentBranch ? Colors.white : theme.textTheme.bodyMedium?.color,
                ),
              ),
              if (isMain && !isCurrentBranch) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'رئيسي',
                    style: TextStyle(fontSize: 9, color: theme.hintColor),
                  ),
                ),
              ],
              if (isCurrentBranch) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'النشط',
                    style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRoleBadge(UserRole role, bool isOwner) {
    String label = 'مساعد';
    Color color = Colors.orange.shade700;
    if (isOwner) {
      label = 'مدير العيادة';
      color = Colors.indigo.shade700;
    } else if (role == UserRole.doctor) {
      label = 'طبيب';
      color = Colors.teal.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Widget _buildStatusBadge(String status, bool isActive) {
    if (!isActive || status == 'pending_activation') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade800.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'قيد التفعيل',
          style: GoogleFonts.cairo(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade800,
          ),
        ),
      );
    } else if (status == 'expired') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade700.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'منتهية',
          style: GoogleFonts.cairo(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade700.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'مفعلة',
        style: GoogleFonts.cairo(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeClinic = ref.watch(activeClinicSummaryProvider);
    final currentUserId = ref.watch(currentUserProvider);
    final selectedBranchId = ref.watch(selectedBranchFilterProvider) ?? currentUserId?.activeBranchId;

    final clinicName = activeClinic?.clinicName ?? 'العيادة';

    String branchLabel = 'الفرع الرئيسي';
    if (selectedBranchId != null && activeClinic != null) {
      final b = activeClinic.branches.where((br) => br.id == selectedBranchId).firstOrNull;
      if (b != null) {
        branchLabel = b.name;
      }
    } else if (activeClinic != null && activeClinic.branches.isNotEmpty) {
      branchLabel = activeClinic.mainBranch?.name ?? 'الفرع الرئيسي';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showSwitcherModal(context, ref),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCompact ? 24 : 28,
                height: isCompact ? 24 : 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_rounded,
                  size: isCompact ? 13 : 15,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clinicName,
                    style: GoogleFonts.cairo(
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    branchLabel,
                    style: GoogleFonts.cairo(
                      fontSize: isCompact ? 9 : 10,
                      height: 1.1,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: isCompact ? 16 : 18,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
