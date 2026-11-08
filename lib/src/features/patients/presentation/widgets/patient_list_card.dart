import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/primitives/app_avatar.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../domain/patient_model.dart';

/// بطاقة المريض في قائمة المرضى — نمط Clinical Utility مسطح ونظيف.
class PatientListCard extends StatelessWidget {
  final PatientModel patient;
  final int fileNo;
  final bool isSelected;
  final Color? doctorColor;
  final VoidCallback onTap;
  final VoidCallback onBookAppointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  const PatientListCard({
    super.key,
    required this.patient,
    required this.fileNo,
    required this.isSelected,
    this.doctorColor,
    required this.onTap,
    required this.onBookAppointment,
    required this.onEdit,
    required this.onDelete,
    required this.canDelete,
  });

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final Color backgroundColor;
    final Border border;

    if (isSelected) {
      backgroundColor = AppColors.accent(context)
          .withValues(alpha: isDark ? 0.16 : 0.07);
      border = Border.all(
        color: AppColors.accent(context),
        width: 1.2,
      );
    } else {
      backgroundColor = AppColors.surface(context);
      border = Border.all(
        color: AppColors.borderSubtle(context),
        width: 1.0,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AppAvatar(
                  name: patient.fullName,
                  size: AppAvatarSize.md,
                  color: doctorColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeName(patient.fullName),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.accent(context)
                              : AppColors.textPrimary(context),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accent(context).withValues(
                                      alpha: isDark ? 0.22 : 0.10,
                                    )
                                  : AppColors.subtle(context),
                              borderRadius: BorderRadius.circular(AppRadii.radiusXs),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent(context)
                                        .withValues(alpha: 0.35)
                                    : AppColors.borderSubtle(context),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '#$fileNo',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.accent(context)
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          if (patient.phone != null &&
                              patient.phone!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                patient.phone!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.textMuted(context),
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'حجز موعد',
                      onPressed: onBookAppointment,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent(context)
                            .withValues(alpha: isDark ? 0.18 : 0.09),
                        foregroundColor: AppColors.accent(context),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.radiusSm),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_task_rounded,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      tooltip: 'خيارات',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textMuted(context),
                        size: 18,
                      ),
                      color: AppColors.surface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.radiusSm),
                        side: BorderSide(color: AppColors.borderSubtle(context)),
                      ),
                      onSelected: (action) {
                        if (action == 'edit') {
                          onEdit();
                        } else if (action == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تعديل',
                                style: GoogleFonts.cairo(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (canDelete)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
