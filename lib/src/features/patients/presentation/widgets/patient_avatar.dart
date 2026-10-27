import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class PatientAvatar extends StatelessWidget {
  final String? gender;
  final Color? doctorColor;
  final double radius;
  final bool showFileNumber;
  final int fileNo;

  const PatientAvatar({
    super.key,
    this.gender,
    this.doctorColor,
    required this.radius,
    this.showFileNumber = false,
    this.fileNo = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoctor = doctorColor != null;
    final avatarColor = gender == 'female'
        ? AppTheme.doctorPalette[4]
        : Theme.of(context).colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasDoctor
                ? LinearGradient(
                    colors: [
                      doctorColor!.withValues(alpha: 0.3),
                      doctorColor!.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      avatarColor.withValues(alpha: 0.3),
                      avatarColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: hasDoctor
                ? Border.all(color: doctorColor!, width: 2)
                : Border.all(color: avatarColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Center(
            child: Icon(
              gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
              color: hasDoctor ? doctorColor : avatarColor,
              size: radius * 0.75,
            ),
          ),
        ),
        if (showFileNumber)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '#$fileNo',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
