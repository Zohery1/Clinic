import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';

enum AppAvatarSize { xs, sm, md, lg, xl }

extension AppAvatarSizeValues on AppAvatarSize {
  double get dim {
    switch (this) {
      case AppAvatarSize.xs:
        return 24;
      case AppAvatarSize.sm:
        return 32;
      case AppAvatarSize.md:
        return 40;
      case AppAvatarSize.lg:
        return 48;
      case AppAvatarSize.xl:
        return 64;
    }
  }

  double get fontSize {
    switch (this) {
      case AppAvatarSize.xs:
        return 10;
      case AppAvatarSize.sm:
        return 12;
      case AppAvatarSize.md:
        return 14;
      case AppAvatarSize.lg:
        return 18;
      case AppAvatarSize.xl:
        return 24;
    }
  }
}

/// Identity avatar with optional network image, deterministic color from
/// the name hash, and auto-derived initials.
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final AppAvatarSize size;
  final Color? color;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AppAvatarSize.md,
    this.color,
  });

  String get _initials {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final s = parts.first;
      return s.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dim = size.dim;
    final seed = color ?? AppColors.doctorColor(name);
    final isDark = AppColors.isDark(context);
    final bg = seed.withValues(alpha: isDark ? 0.28 : 0.14);
    final fg = isDark ? seed : seed;

    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: seed.withValues(alpha: 0.25), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsText(fg, size.fontSize),
            )
          : Center(
              child: Text(
                _initials,
                style: GoogleFonts.cairo(
                  fontSize: size.fontSize,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  height: 1.0,
                ),
              ),
            ),
    );
  }

  Widget _initialsText(Color color, double fontSize) => Center(
        child: Text(
          _initials,
          style: GoogleFonts.cairo(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
      );
}
