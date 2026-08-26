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
  const ClinicSwitcherButton({super.key});

  void _showSwitcherModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
            margin: const EdgeInsets.only(top: 40, bottom: 20, left: 16, right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final clinicsList = ref.watch(userClinicsProvider);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modal Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              color: theme.colorScheme.primary,
                              size: 20,
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
                                    fontSize: 15,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                                Text(
                                  'اختر العيادة أو الفرع للعمل عليه',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
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

                    // Clinics List
                    Flexible(
                      child: clinicsList.when(
                        data: (clinics) {
                          if (clinics.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'لا توجد عيادات مسجلة',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shrinkWrap: true,
                            itemCount: clinics.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, idx) {
                              final clinic = clinics[idx];
                              final isActive = clinic.clinicId == (user?.activeClinicId ?? user?.clinicId);

                              return _buildClinicCard(
                                context,
                                ref,
                                clinic,
                                isActive,
                                user,
                                ctx,
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'تعذر تحميل العيادات',
                              style: GoogleFonts.cairo(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Bottom Actions
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

  static Widget _buildClinicCard(
    BuildContext context,
    WidgetRef ref,
    ClinicSummaryModel clinic,
    bool isActive,
    UserModel? user,
    BuildContext bottomSheetContext,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? primaryColor.withValues(alpha: 0.04)
            : theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? primaryColor : AppTheme.darkBorder.withValues(alpha: 0.2),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clinic Main Row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              if (!isActive) {
                final success = await ref
                    .read(clinicsControllerProvider.notifier)
                    .switchActiveClinic(clinic.clinicId);
                if (success && bottomSheetContext.mounted) {
                  Navigator.of(bottomSheetContext).pop();
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isActive
                        ? primaryColor
                        : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: isActive ? Colors.white : theme.textTheme.bodyLarge?.color,
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
                                  fontSize: 14,
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
                        Text(
                          clinic.branches.isEmpty
                              ? 'الفرع الرئيسي'
                              : '${clinic.branches.length} ${clinic.branches.length == 1 ? "فرع" : "فروع"}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'نشطة الآن',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Branches selection for active clinic
          if (isActive && clinic.branches.length > 1) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفروع التابعة:',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: clinic.branches.map((branch) {
                      final selectedBranch = ref.watch(selectedBranchFilterProvider);
                      final isSelectedBranch = selectedBranch == branch.id;

                      return ChoiceChip(
                        label: Text(branch.name),
                        labelStyle: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: isSelectedBranch ? FontWeight.bold : FontWeight.w600,
                          color: isSelectedBranch ? Colors.white : theme.textTheme.bodyMedium?.color,
                        ),
                        selected: isSelectedBranch,
                        selectedColor: primaryColor,
                        backgroundColor: theme.colorScheme.surface,
                        onSelected: (selected) {
                          ref.read(selectedBranchFilterProvider.notifier).state =
                              selected ? branch.id : null;
                          if (bottomSheetContext.mounted) {
                            Navigator.of(bottomSheetContext).pop();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeClinic = ref.watch(activeClinicSummaryProvider);
    final selectedBranchId = ref.watch(selectedBranchFilterProvider);

    final clinicName = activeClinic?.clinicName ?? 'العيادة';

    String branchLabel = 'جميع الفروع';
    if (selectedBranchId != null && activeClinic != null) {
      final b = activeClinic.branches.where((br) => br.id == selectedBranchId).firstOrNull;
      if (b != null) branchLabel = b.name;
    } else if (activeClinic != null && activeClinic.branches.isNotEmpty) {
      branchLabel = activeClinic.mainBranch?.name ?? 'الفرع الرئيسي';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showSwitcherModal(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.darkBorder.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business_rounded,
                  size: 15,
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
                      fontSize: 12.5,
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
                      fontSize: 10,
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
                size: 18,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
