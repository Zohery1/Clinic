import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import 'reports_controller.dart';
import 'report_detail_screen.dart';
import '../../../core/widgets/clinic_dialog.dart';

part 'reports_screen_parts.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedSubTab = 0; // 0 for daily logs, 1 for monthly logs

  // Default date range: last 90 days
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 89));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _calculateTrend(double current, double previous) {
    if (previous == 0) return 'مستقر (لا توجد بيانات سابقة)';
    final percent = ((current - previous) / previous) * 100;
    final prefix = percent >= 0 ? '+' : '';
    return '$prefix${percent.toStringAsFixed(1)}% مقارنة بالفترة السابقة';
  }

  String get _rangeParamString {
    final startStr = "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";
    final endStr = "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";
    return "${startStr}_$endStr";
  }

  bool get _isFiltered {
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 89));
    final currentStart = DateTime(_startDate.year, _startDate.month, _startDate.day);
    return (currentStart.difference(defaultStart).inDays).abs() > 1;
  }

  void _resetToDefault() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 89));
      _endDate = DateTime.now();
    });
  }



  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final monthRevenueAsync = ref.watch(monthRevenueProvider);
    final weeklyRevenueAsync = ref.watch(weeklyRevenueProvider);
    final sixWeeksRevenueAsync = ref.watch(sixWeeksRevenueProvider);

    final dailyStatsAsync = user != null
        ? ref.watch(dailyStatsProvider(_rangeParamString))
        : const AsyncValue<List<Map<String, dynamic>>>.loading();
    final monthlyStatsAsync = user != null
        ? ref.watch(monthlyStatsProvider)
        : const AsyncValue<List<Map<String, dynamic>>>.loading();

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (user == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Text('يرجى تسجيل الدخول أولاً',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ),
      );
    }

    if (user.role == UserRole.secretary && !user.canViewReports) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: AppTheme.cardDecorationFlat(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline_rounded, size: 56, color: AppTheme.error),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تم تقييد وصول السكرتيرة للتقارير',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'قام الطبيب بإيقاف صلاحية رؤية الإيرادات والتقارير المالية عن حسابك. يرجى مراجعة إدارة العيادة عند الحاجة.',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isDesktop
          ? Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: _buildFinancialAnalyticsTab(
                todayRevenueAsync,
                monthRevenueAsync,
                weeklyRevenueAsync,
                sixWeeksRevenueAsync,
                dailyStatsAsync,
                monthlyStatsAsync,
              ),
            )
          : Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text('التقارير المالية والتحليلات'),
              ),
              body: _buildFinancialAnalyticsTab(
                todayRevenueAsync,
                monthRevenueAsync,
                weeklyRevenueAsync,
                sixWeeksRevenueAsync,
                dailyStatsAsync,
                monthlyStatsAsync,
              ),
            ),
    );
  }

  // تبويب التحليلات المالية

  List<double> _getDailyPoints(List<Map<String, dynamic>> dailyData, double todayRevenue) {
    final now = DateTime.now();
    final Map<String, double> revenueMap = {};
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      revenueMap[dateStr] = 0.0;
    }
    for (final d in dailyData) {
      final dateStr = d['date'] as String;
      if (revenueMap.containsKey(dateStr)) {
        revenueMap[dateStr] = (d['revenue'] as num).toDouble();
      }
    }
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    revenueMap[todayStr] = todayRevenue;

    final sortedKeys = revenueMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => revenueMap[k]!).toList();
  }


  List<double> _getMonthlyPoints(List<Map<String, dynamic>> monthlyData, double thisMonthRevenue) {
    final now = DateTime.now();
    final Map<String, double> revenueMap = {};
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthStr = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      revenueMap[monthStr] = 0.0;
    }
    for (final m in monthlyData) {
      final monthStr = m['month'] as String;
      if (revenueMap.containsKey(monthStr)) {
        revenueMap[monthStr] = (m['revenue'] as num).toDouble();
      }
    }
    final thisMonthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    revenueMap[thisMonthStr] = thisMonthRevenue;

    final sortedKeys = revenueMap.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => revenueMap[k]!).toList();
  }

  // بطاقة الدخل البصرية الممتازة (Stitch Design)


  // جدول سجلات الأيام التفصيلي

  // جدول سجلات الشهور التراكمي

}

// رسم خط الاتجاه البياني البسيط مع تعبئة تدرجية (Sparkline Painter)
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  _SparklinePainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minVal = points.reduce((a, b) => a < b ? a : b);
    // When all values equal, show a gentle mid-line at 60% height
    final range = maxVal - minVal > 0 ? maxVal - minVal : null;

    // Points come in newest-first order (index 0 = most recent).
    // Painter maps: i=0 (newest) → x=0 (LEFT), i=n-1 (oldest) → x=size.width (RIGHT).
    // This gives RTL reading: past on the right, present on the left.
    final List<Offset> offsets = [];
    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX; // LTR index → newest at LEFT (x=0), oldest at RIGHT (x=width)
      final double y;
      if (range == null) {
        y = size.height * 0.4;
      } else {
        y = size.height - ((points[i] - minVal) / range) * size.height * 0.85 - size.height * 0.07;
      }
      offsets.add(Offset(x, y));
    }

    // Draw gradient fill beneath the line
    if (offsets.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(offsets.first.dx, size.height);
      fillPath.lineTo(offsets.first.dx, offsets.first.dy);
      for (int i = 1; i < offsets.length; i++) {
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final cpX = (prev.dx + curr.dx) / 2;
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
      fillPath.lineTo(offsets.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.01)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Draw the line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < offsets.length; i++) {
      if (i == 0) {
        linePath.moveTo(offsets[i].dx, offsets[i].dy);
      } else {
        // Smooth cubic bezier
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final cpX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Dot at the newest point (leftmost = offsets.first, since index 0 = newest = x=0)
    final dotO = offsets.first;
    canvas.drawCircle(dotO, 3.0, Paint()..color = color);
    canvas.drawCircle(dotO, 3.0, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.points != points;
}



