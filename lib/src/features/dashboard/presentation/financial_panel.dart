import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../reports/presentation/reports_controller.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../../appointments/domain/appointment_model.dart';
import '../../patients/presentation/patient_details_dialog.dart';

/// لوحة الإحصائيات المالية الجانبية للكمبيوتر (1/3 من الداشبورد)
/// تحتوي على رسم بياني مصغر للإيراد الأسبوعي وجدول المعاملات المالية الأخيرة
class FinancialPanel extends ConsumerWidget {
  const FinancialPanel({super.key});

  String _getShortDay(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final dayName = intl.DateFormat('EEEE', 'ar').format(date);
      // إزالة ال التعريف لجعل النص أقصر وأنسب للرسم البياني (مثال: السبت -> سبت)
      if (dayName.startsWith('ال')) {
        return dayName.substring(2);
      }
      return dayName;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyRevenueAsync = ref.watch(weeklyRevenueProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── الرسم البياني الأسبوعي (Weekly Revenue Chart) ───
        _buildWeeklyChartCard(context, weeklyRevenueAsync),
        const SizedBox(height: 16),
        // ─── المعاملات المالية الأخيرة ───
        Expanded(
          child: _buildRecentTransactions(context, appointmentsAsync),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartCard(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> weeklyRevenueAsync,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أداء الإيرادات الأسبوعية',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              Icon(
                Icons.analytics_outlined,
                color: theme.hintColor,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: weeklyRevenueAsync.when(
              data: (dataList) {
                if (dataList.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد بيانات متاحة',
                      style: GoogleFonts.cairo(fontSize: 12, color: theme.hintColor),
                    ),
                  );
                }

                // حساب القيمة القصوى لتحديد الارتفاع النسبي
                final double maxRevenue = dataList
                    .map((item) => (item['revenue'] as num? ?? 0.0).toDouble())
                    .fold(0.0, (prev, current) => current > prev ? current : prev);
                
                final double divisor = maxRevenue == 0.0 ? 1.0 : maxRevenue;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: dataList.map((item) {
                    final revenue = (item['revenue'] as num? ?? 0.0).toDouble();
                    final ratio = revenue / divisor;
                    final shortDay = _getShortDay(item['date'] as String);

                    return Expanded(
                      child: Tooltip(
                        message: '${revenue.toStringAsFixed(0)} ج.م',
                        textStyle: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 11),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxHeight = constraints.maxHeight;
                                  final barHeight = (maxHeight * ratio).clamp(4.0, maxHeight);
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 12,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: revenue > 0
                                            ? primaryColor
                                            : theme.dividerColor.withValues(alpha: 0.5),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(3),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              shortDay,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'خطأ في التحميل',
                  style: GoogleFonts.cairo(fontSize: 12, color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'العمليات المالية الأخيرة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  'اليوم',
                  style: GoogleFonts.cairo(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Table header
          Container(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'المريض',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'المبلغ',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'الحالة',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Rows
          Expanded(
            child: appointmentsAsync.when(
              data: (appointments) {
                final list = List<AppointmentModel>.from(appointments);
                list.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'لا توجد حجوزات اليوم',
                        style: GoogleFonts.cairo(
                          color: theme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final appt = list[index];
                    return _buildTransactionRow(context, appt);
                  },
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, AppointmentModel appt) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final warningColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);

    final isCompleted = appt.status == 'completed';
    final isCancelled = appt.status.startsWith('cancelled');
    
    String statusText = 'بالانتظار';
    Color statusColor = warningColor;
    
    if (isCompleted) {
      statusText = 'مكتمل';
      statusColor = successColor;
    } else if (isCancelled) {
      statusText = 'ملغي';
      statusColor = theme.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => PatientDetailsDialog(
                    clinicId: appt.clinicId,
                    patient: appt.patient,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      appt.patient.fullName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 13,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${appt.totalPaid.toStringAsFixed(0)} ج.م',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.cairo(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
