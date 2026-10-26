import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/motion.dart';

class AppStepperStep {
  final String title;
  final String description;
  final IconData icon;
  const AppStepperStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AppStepper extends StatelessWidget {
  final List<AppStepperStep> steps;
  final int currentIndex;
  final ValueChanged<int>? onStepTap;

  const AppStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentStep = steps[currentIndex.clamp(0, steps.length - 1)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شريط وصف الخطوة الحالية ونسبة الإنجاز
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'الخطوة ${currentIndex + 1} من ${steps.length}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  currentStep.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            Text(
              currentStep.description,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),

        // شريط الدوائر والخطوات المترابطة أفقياً
        Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _StepNode(
                index: i,
                currentIndex: currentIndex,
                step: steps[i],
                onTap: (i < currentIndex && onStepTap != null) ? () => onStepTap!(i) : null,
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i < currentIndex
                          ? AppColors.success
                          : AppColors.borderSubtle(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final int index;
  final int currentIndex;
  final AppStepperStep step;
  final VoidCallback? onTap;

  const _StepNode({
    required this.index,
    required this.currentIndex,
    required this.step,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < currentIndex;
    final isCurrent = index == currentIndex;

    final circleBg = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.subtle(context);

    final circleFg = (isCompleted || isCurrent)
        ? Colors.white
        : AppColors.textMuted(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: AppMotion.easeOutCubic,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: circleBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrent
                ? AppColors.primary
                : isCompleted
                    ? AppColors.success
                    : AppColors.border(context),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: circleFg,
                  ),
                ),
        ),
      ),
    );
  }
}