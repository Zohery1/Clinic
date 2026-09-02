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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isHorizontal = constraints.maxWidth >= 700;
        return AnimatedSwitcher(
          duration: AppMotion.normal,
          switchInCurve: AppMotion.easeOutCubic,
          switchOutCurve: AppMotion.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: isHorizontal
              ? _Horizontal(
                  key: const ValueKey('h'),
                  steps: steps,
                  currentIndex: currentIndex,
                  onStepTap: onStepTap,
                )
              : _Vertical(
                  key: const ValueKey('v'),
                  steps: steps,
                  currentIndex: currentIndex,
                  onStepTap: onStepTap,
                ),
        );
      },
    );
  }
}

class _Vertical extends StatelessWidget {
  final List<AppStepperStep> steps;
  final int currentIndex;
  final ValueChanged<int>? onStepTap;
  const _Vertical({
    super.key,
    required this.steps,
    required this.currentIndex,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepRow(
            step: steps[i],
            index: i,
            currentIndex: currentIndex,
            onTap: (i < currentIndex && onStepTap != null) ? () => onStepTap!(i) : null,
            horizontal: false,
          ),
          if (i < steps.length - 1)
            _Connector(
              horizontal: false,
              active: i < currentIndex,
            ),
        ],
      ],
    );
  }
}

class _Horizontal extends StatelessWidget {
  final List<AppStepperStep> steps;
  final int currentIndex;
  final ValueChanged<int>? onStepTap;
  const _Horizontal({
    super.key,
    required this.steps,
    required this.currentIndex,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _StepRow(
              step: steps[i],
              index: i,
              currentIndex: currentIndex,
              onTap: (i < currentIndex && onStepTap != null) ? () => onStepTap!(i) : null,
              horizontal: true,
            ),
          ),
          if (i < steps.length - 1)
            SizedBox(
              width: 24,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _Connector(horizontal: true, active: i < currentIndex),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final AppStepperStep step;
  final int index;
  final int currentIndex;
  final VoidCallback? onTap;
  final bool horizontal;

  const _StepRow({
    required this.step,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == currentIndex;
    final isCompleted = index < currentIndex;
    final isUpcoming = index > currentIndex;

    final circleBg = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.primary
            : AppColors.surface(context);
    final circleBorder = isUpcoming
        ? AppColors.border(context)
        : Colors.transparent;
    final circleFg = (isCompleted || isCurrent) ? Colors.white : AppColors.textMuted(context);

    final titleColor = isCurrent
        ? AppColors.primary
        : isCompleted
            ? AppColors.textPrimary(context)
            : AppColors.textMuted(context);
    final descColor = isCurrent
        ? AppColors.textSecondary(context)
        : AppColors.textMuted(context);

    final node = AnimatedContainer(
      duration: AppMotion.normal,
      curve: AppMotion.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: circleBg,
        shape: BoxShape.circle,
        border: Border.all(color: circleBorder, width: 1.5),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : isUpcoming
                ? Icon(step.icon, size: 16, color: circleFg)
                : Text(
                    '${index + 1}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: circleFg,
                    ),
                  ),
      ),
    );

    final titleStyle = GoogleFonts.cairo(
      fontSize: horizontal ? 13 : 14,
      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
      color: titleColor,
      height: 1.3,
    );

    final descStyle = GoogleFonts.cairo(
      fontSize: horizontal ? 11.5 : 12,
      fontWeight: FontWeight.w500,
      color: descColor,
      height: 1.4,
    );

    final labels = Column(
      crossAxisAlignment: horizontal ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!horizontal) ...[
          Text(step.title, style: titleStyle, textAlign: TextAlign.start),
          const SizedBox(height: 2),
          Text(step.description, style: descStyle, textAlign: TextAlign.start),
        ] else ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            step.title,
            style: titleStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            step.description,
            style: descStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    final content = horizontal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [node, labels],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              node,
              const SizedBox(width: AppSpace.md),
              Expanded(child: labels),
            ],
          );

    final inner = Padding(
      padding: EdgeInsets.symmetric(vertical: horizontal ? 0 : AppSpace.xs),
      child: content,
    );

    if (onTap == null) return inner;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: horizontal ? 0 : AppSpace.xs),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brSm,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xs),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool horizontal;
  final bool active;
  const _Connector({required this.horizontal, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.borderSubtle(context);
    if (horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: AppMotion.normal,
          height: 1.5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15.5),
      child: AnimatedContainer(
        duration: AppMotion.normal,
        width: 1.5,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}