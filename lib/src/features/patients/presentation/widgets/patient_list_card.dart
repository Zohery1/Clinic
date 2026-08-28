import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_motion.dart';
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
    final isSelected = widget.isSelected;
    final isHovered = _isHovered;
    final showHoverEffect = isHovered && !isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        margin: const EdgeInsets.only(bottom: 8),
        transform: showHoverEffect ? (Matrix4.identity()..scale(1.015)) : Matrix4.identity(),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              )
            : AppTheme.cardDecoration(context).copyWith(
                boxShadow: showHoverEffect
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : AppTheme.cardDecoration(context).boxShadow,
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
                  showFileNumber: true,
                  fileNo: widget.fileNo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeName(widget.patient.fullName),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.patient.phone != null && widget.patient.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.patient.phone!,
                          style: GoogleFonts.jetBrainsMono(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            fontSize: 13,
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
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_task_rounded, color: AppTheme.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'خيارات أخرى',
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textHint, size: 18),
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
                              Icon(Icons.edit_outlined, color: AppTheme.primary, size: 16),
                              SizedBox(width: 8),
                              Text('تعديل البيانات', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        if (widget.canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 16),
                                SizedBox(width: 8),
                                Text('حذف المريض', style: TextStyle(color: AppTheme.error, fontSize: 13)),
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
