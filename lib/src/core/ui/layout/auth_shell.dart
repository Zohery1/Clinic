import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;
        final canvas = AppColors.canvas(context);

        if (!isWide) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: canvas,
              body: SafeArea(
                child: _MobileAuthLayout(
                  footer: footer,
                  child: child,
                ),
              ),
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
                // اللوحة السريرية المتقدمة (العرض المرئي للمنظومة)
                const Expanded(
                  flex: 11,
                  child: _ClinicalShowcasePanel(),
                ),
                // لوحة إدخال البيانات ونموذج المصادقة
                Expanded(
                  flex: 9,
                  child: SafeArea(
                    child: _DesktopFormContainer(
                      footer: footer,
                      child: child,
                    ),
                  ),
                ),
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

/// حاوية النموذج لسطح المكتب
class _DesktopFormContainer extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const _DesktopFormContainer({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: AppSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpace.xxxl),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.borderSubtle(context),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.35 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                  ],
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

/// حاوية النموذج للهواتف المحمولة
class _MobileAuthLayout extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const _MobileAuthLayout({required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // رأس هوية العيادة على الموبايل
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'منظومة عيادتي',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary(context),
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'إدارة العيادات والمراكز الطبية',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(context),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              // بطاقة النموذج
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xxl),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.borderSubtle(context),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: AppColors.isDark(context) ? 0.3 : 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),

              if (footer != null) ...[
                const SizedBox(height: AppSpace.md),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// اللوحة السريرية المتقدمة لسطح المكتب (Showcase Panel)
/// تعرض محاكاة حية لطابور العيادة الذكي ومؤشرات التشغيل السريرية
class _ClinicalShowcasePanel extends StatelessWidget {
  const _ClinicalShowcasePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF090D1A), // Deep Obsidian Navy
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية شبكية سريرية دقيقة
          CustomPaint(
            painter: _PrecisionGridPainter(),
            size: Size.infinite,
          ),

          // المحتوى السريري
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // شريط الرأس: هوية المنظومة واعتماد الأمان
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'عيادتي · Eyadaty',
                                style: GoogleFonts.cairo(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'نظام إدارة العيادات والمراكز الطبية التخصصية',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'نظام سريري متصل 100%',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // جسم اللوحة: المحاكاة الحية للطابور السريري
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'منظومة سريرية متكاملة لعيادة الغد',
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        'إدارة دقيقة لمواعيد المرضى، طابور كشف ذكي لحظي عبر واتساب، سجل طبي إلكتروني موحد، وتقارير مالية فورية.',
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCBD5E1),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),

                      // البطاقة التفاعلية الحية لطابور العيادة
                      _LiveClinicQueueWidget(),
                    ],
                  ),

                  // شريط الثقة والمواصفات السريرية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTrustItem(Icons.verified_user_rounded, 'تشفير طبي عالي الأمان HIPAA'),
                      _buildTrustItem(Icons.mark_chat_unread_rounded, 'تذكيرات واتساب مؤتمتة بدون كود'),
                      _buildTrustItem(Icons.hub_rounded, 'متعدد الفروع والأطباء والمساعدين'),
                      Text(
                        'الإصدار السريري v2.0 Enterprise',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// بطاقة المحاكاة السريرية اللحظية (Live EMR & Queue Card)
class _LiveClinicQueueWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة: العيادة الحالية والغرفة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'غرفة الكشف رقم 2 · جراحة العظام',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF93C5FD),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'كشف جاري الآن (08:24 دقيقة)',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          // تفاصيل المريض داخل غرفة الكشف
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF334155),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#101',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أحمد محمود عبد العزيز (42 سنة)',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'كشف جديد تخصصي + سونار حركي للمفصل · د. عبد الرحمن الزهيري',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'الضغط: 120/80',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),

          // شريط الانتظار القادم
          Row(
            children: [
              Expanded(
                child: _buildQueueMiniChip(
                  ticket: '#102',
                  name: 'سارة كمال الشناوي',
                  status: 'التالي بالانتظار',
                  isNext: true,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _buildQueueMiniChip(
                  ticket: '#103',
                  name: 'محمود حسن خليل',
                  status: 'في صالة الانتظار',
                  isNext: false,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _buildQueueMiniChip(
                  ticket: '#104',
                  name: 'نادية عبد الله إبراهيم',
                  status: 'في صالة الانتظار',
                  isNext: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueMiniChip({
    required String ticket,
    required String name,
    required String status,
    required bool isNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isNext
            ? const Color(0xFF0284C7).withValues(alpha: 0.15)
            : const Color(0xFF0F172A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isNext
              ? const Color(0xFF0284C7).withValues(alpha: 0.4)
              : const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isNext ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                ),
              ),
              Text(
                status,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isNext ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// خلفية الشبكة السريرية الدقيقة
class _PrecisionGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.8;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // علامات التوجيه السريرية الدقيقة
    final markerPaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.15)
      ..strokeWidth = 1.2;

    for (double x = spacing * 2; x < size.width; x += spacing * 5) {
      for (double y = spacing * 2; y < size.height; y += spacing * 5) {
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), markerPaint);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), markerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
