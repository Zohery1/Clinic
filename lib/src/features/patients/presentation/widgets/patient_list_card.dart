import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/motion.dart';
import '../../domain/patient_model.dart';
import 'patient_avatar.dart';
import 'hover_scale_button.dart';

class PatientListCard extends StatefulWidget {
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

  @override
  State<PatientListCard> createState() => _PatientListCardState();
}

class _PatientListCardState extends State<PatientListCard> {
  bool _isHovered = false;

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
    final isSelected = widget.isSelected;
    final isHovered = _isHovered;
    final showHoverEffect = isHovered && !isSelected;

    final Color backgroundColor;
    final Border border;
    final List<BoxShadow>? boxShadow;

    if (isSelected) {
      backgroundColor = isDark
          ? AppColors.primary.withValues(alpha: 0.15)
          : AppColors.primarySubtle;
      border = Border.all(
        color: AppColors.primary,
        width: 1.5,
      );
      boxShadow = [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (showHoverEffect) {
      backgroundColor =
          AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05);
      border = Border.all(
        color: AppColors.primary.withValues(alpha: 0.35),
        width: 1,
      );
      boxShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      backgroundColor = AppColors.surface(context);
      border = Border.all(
        color: AppColors.borderSubtle(context),
        width: 1,
      );
      boxShadow = null;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: border,
          boxShadow: boxShadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                PatientAvatar(
                  gender: widget.patient.gender,
                  doctorColor: widget.doctorColor,
                  radius: 22,
                  showFileNumber: false,
                  fileNo: widget.fileNo,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(
                                      alpha: isDark ? 0.25 : 0.15,
                                    )
                                  : (isDark
                                      ? AppColors.darkSubtle
                                      : AppColors.lightSubtle),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : AppColors.borderSubtle(context),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '#${widget.fileNo}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _capitalizeName(widget.patient.fullName),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.patient.phone != null &&
                          widget.patient.phone!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.patient.phone!,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.textMuted(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HoverScaleButton(
                      tooltip: 'حجز موعد جديد',
                      onTap: widget.onBookAppointment,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primarySubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'خيارات أخرى',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textMuted(context),
                        size: 18,
                      ),
                      onSelected: (action) {
                        if (action == 'edit') {
                          widget.onEdit();
                        } else if (action == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'تعديل البيانات',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (widget.canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'حذف المريض',
                                  style: TextStyle(
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
