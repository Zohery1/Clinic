import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Soft Structuralism "Button-in-Button" CTA with magnetic hover simulation
/// and micro-spring touch response.
///
/// - Outer Tactile Pill: 52px height, 26px radius, primary gradient with ambient glow.
/// - Inner Action Capsule: 36x36px, 18px radius, translucent white capsule holding icon or micro-spinner.
/// - Magnetic Hover (Desktop/Web): Mouse tracking with clamped translation offset (up to 5px).
/// - Spring Tap (Mobile): Elastic scale-down (0.97) on pointer press.
class MagneticNestedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double? width;
  final double height;
  final bool isDangerous;
  final bool enabled;

  const MagneticNestedButton({
    super.key,
    required this.label,
    this.icon = Icons.arrow_back_rounded, // default back/forward arrow
    this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.primaryColor,
    this.secondaryColor,
    this.width,
    this.height = 52.0,
    this.isDangerous = false,
    this.enabled = true,
  });

  @override
  State<MagneticNestedButton> createState() => _MagneticNestedButtonState();
}

class _MagneticNestedButtonState extends State<MagneticNestedButton> {
  Offset _magneticOffset = Offset.zero;
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleHover(PointerHoverEvent event, BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
    final height = widget.height;
    final center = Offset(width / 2, height / 2);
    final delta = event.localPosition - center;

    setState(() {
      _magneticOffset = Offset(
        (delta.dx / (width / 2) * 5.0).clamp(-5.0, 5.0),
        (delta.dy / (height / 2) * 3.5).clamp(-3.5, 3.5),
      );
    });
  }

  void _handleExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
      _magneticOffset = Offset.zero;
    });
  }

  void _handleEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInteractive = widget.enabled && !widget.isLoading && widget.onPressed != null;

    final basePrimary = widget.isDangerous
        ? AppColors.error
        : (widget.primaryColor ?? AppColors.primary);
    final baseSecondary = widget.isDangerous
        ? const Color(0xFFB91C1C)
        : (widget.secondaryColor ?? AppColors.primaryDark);

    final gradientColors = isInteractive
        ? [basePrimary, baseSecondary]
        : [
            isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
            isDark ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
          ];

    final glowColor = isInteractive
        ? basePrimary.withValues(alpha: isDark ? 0.45 : 0.35)
        : Colors.transparent;

    final targetScale = _isPressed
        ? 0.97
        : (_isHovered && isInteractive ? 1.018 : 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: isInteractive ? _handleEnter : null,
          onHover: isInteractive ? (e) => _handleHover(e, constraints) : null,
          onExit: isInteractive ? _handleExit : null,
          child: GestureDetector(
            onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: isInteractive ? widget.onPressed : null,
            child: AnimatedScale(
              scale: targetScale,
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              child: AnimatedSlide(
                offset: Offset(
                  _magneticOffset.dx / (constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0),
                  _magneticOffset.dy / widget.height,
                ),
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: _isHovered ? 20 : 14,
                        spreadRadius: _isHovered ? 1 : 0,
                        offset: Offset(0, _isHovered ? 8 : 5),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.25),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: widget.width == null ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      // Label Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: Text(
                            widget.isLoading
                                ? (widget.loadingLabel ?? 'جاري الحفظ...')
                                : widget.label,
                            key: ValueKey<String>(
                              widget.isLoading
                                  ? (widget.loadingLabel ?? 'loading')
                                  : widget.label,
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      // Inner Action Capsule (36x36px)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: widget.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    widget.icon ?? Icons.arrow_back_rounded,
                                    size: 18,
                                    color: Colors.white,
                                    key: const ValueKey('button_icon'),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
