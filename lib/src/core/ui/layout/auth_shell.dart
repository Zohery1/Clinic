import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import '../tokens/shadows.dart';

class AuthShell extends StatelessWidget {
  final Widget child;
  final String heroTitle;
  final String heroSubtitle;
  final List<AuthHeroBullet> heroBullets;
  final Widget? footer;

  const AuthShell({
    super.key,
    required this.child,
    required this.heroTitle,
    required this.heroSubtitle,
    this.heroBullets = const [
      AuthHeroBullet(icon: Icons.shield_outlined, text: 'موثوق وآمن لتخزين بيانات المرضى'),
      AuthHeroBullet(icon: Icons.notifications_active_outlined, text: 'تذكيرات واتساب تلقائية بدون كود'),
      AuthHeroBullet(icon: Icons.business_rounded, text: 'يدعم عدة فروع وأطباء في عيادة واحدة'),
    ],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final canvas = AppColors.canvas(context);
        if (!isWide) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: canvas,
              body: SafeArea(child: _FormContainer(child: child, footer: footer)),
            ),
          );
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: canvas,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: SafeArea(child: _FormContainer(child: child, footer: footer))),
                Expanded(flex: 5, child: _HeroPanel(title: heroTitle, subtitle: heroSubtitle, bullets: heroBullets)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AuthHeroBullet {
  final IconData icon;
  final String text;
  const AuthHeroBullet({required this.icon, required this.text});
}

class _FormContainer extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  const _FormContainer({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final showMobileLogo = MediaQuery.of(context).size.width < 900;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showMobileLogo) ...[
                const _MobileBrandMark(),
                const SizedBox(height: AppSpace.xxl),
              ],
              Container(
                padding: const EdgeInsets.all(AppSpace.xxxl),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: AppRadii.brLg,
                  border: Border.all(color: AppColors.borderSubtle(context)),
                  boxShadow: AppShadows.md(context),
                ),
                child: child,
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpace.lg),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBrandMark extends StatelessWidget {
  const _MobileBrandMark();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadii.brMd, boxShadow: AppShadows.sm(context)),
      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AuthHeroBullet> bullets;
  const _HeroPanel({required this.title, required this.subtitle, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _HeroGradient(),
        const _HeroMeshBlobs(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: AppRadii.brMd,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.displayLg(Colors.white)),
                    const SizedBox(height: AppSpace.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(subtitle, style: AppTypography.bodyLg(Colors.white.withValues(alpha: 0.8))),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    ...bullets.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.md),
                          child: _HeroBullet(icon: b.icon, text: b.text),
                        )),
                  ],
                ),
                Text('عيادتي · v1.1.0', style: AppTypography.caption(Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroGradient extends StatelessWidget {
  const _HeroGradient();
  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

class _HeroMeshBlobs extends StatelessWidget {
  const _HeroMeshBlobs();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(top: -80, right: -60, child: _Blob(size: 320)),
        Positioned(bottom: -120, left: -80, child: _Blob(size: 380)),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  const _Blob({required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroBullet({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: AppTypography.bodyMd(Colors.white))),
      ],
    );
  }
}
