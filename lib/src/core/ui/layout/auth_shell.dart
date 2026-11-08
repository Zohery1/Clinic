import 'package:flutter/material.dart';

import '../primitives/app_logo.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

class AuthHeroBullet {
  final IconData icon;
  final String text;
  const AuthHeroBullet({required this.icon, required this.text});
}

/// Shared authentication frame.
///
/// Desktop gets a real brand panel built from clinic truths, not a flat color
/// block. Mobile keeps the mark and drops the panel.
class AuthShell extends StatelessWidget {
  final Widget child;
  final String heroTitle;
  final String heroSubtitle;
  final List<AuthHeroBullet>? heroBullets;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.child,
    required this.heroTitle,
    required this.heroSubtitle,
    this.heroBullets,
    this.footer,
  });

  static const List<AuthHeroBullet> _defaultBullets = <AuthHeroBullet>[
    AuthHeroBullet(
      icon: Icons.event_available_rounded,
      text: 'مواعيد وطابور يومي واضح',
    ),
    AuthHeroBullet(
      icon: Icons.folder_shared_rounded,
      text: 'ملف طبي موحد لكل مريض',
    ),
    AuthHeroBullet(
      icon: Icons.query_stats_rounded,
      text: 'أرقام العيادة جاهزة وقت الحاجة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.canvas(context),
            body: wide
                ? _desktop(context)
                : _mobile(context),
          ),
        );
      },
    );
  }

  Widget _desktop(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 5, child: _BrandPanel(
          title: heroTitle,
          subtitle: heroSubtitle,
          bullets: heroBullets ?? _defaultBullets,
        )),
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xxxl,
                vertical: AppSpace.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FormCard(child: child),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpace.lg),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.xl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 52)),
                const SizedBox(height: AppSpace.md),
                Text(
                  heroTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  heroSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted(context),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                _FormCard(child: child),
                if (footer != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: child,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AuthHeroBullet> bullets;

  const _BrandPanel({
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: <Color>[AppColors.primaryDark, Color(0xFF0A1330)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -130,
            left: -110,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.09),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(
                  size: 40,
                  showWordmark: true,
                  title: 'عيادتي',
                  subtitle: 'نظام إدارة العيادة',
                  onDark: true,
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.68),
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxxl),
                      for (final bullet in bullets) ...[
                        _BulletRow(bullet: bullet),
                        const SizedBox(height: AppSpace.md),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'نظام إدارة العيادات',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final AuthHeroBullet bullet;

  const _BulletRow({required this.bullet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Icon(bullet.icon, size: 17, color: Colors.white),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(
            bullet.text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
