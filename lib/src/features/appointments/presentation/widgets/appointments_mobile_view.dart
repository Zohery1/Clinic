import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/double_bezel_card.dart';
import '../../../../core/widgets/staggered_card_entry.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/appointment_model.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'appointments_calendar_strip.dart';
import 'appointment_card_item.dart';

/// العرض المخصص للهاتف لشاشة المواعيد بتصميم Soft Structuralism
class AppointmentsMobileView extends ConsumerStatefulWidget {
  final UserModel user;
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  final DateTime selectedDate;

  const AppointmentsMobileView({
    super.key,
    required this.user,
    required this.appointmentsAsync,
    required this.selectedDate,
  });

  @override
  ConsumerState<AppointmentsMobileView> createState() => _AppointmentsMobileViewState();
}

class _AppointmentsMobileViewState extends ConsumerState<AppointmentsMobileView> {
  int _selectedFilterIndex = 0;

  Widget _buildRevenueSummary(BuildContext context, WidgetRef ref, int totalAppts) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // بطاقة إيرادات اليوم بتقنية Double-Bezel
        Expanded(
          child: DoubleBezelCard(
            outerRadius: 18.0,
            innerRadius: 15.5,
            outerPadding: const EdgeInsets.all(2.5),
            innerPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إيرادات اليوم',
                      style: TextStyle(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.18 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                todayRevenueAsync.when(
                  data: (rev) => Row(
                    children: [
                      Text(
                        rev.toStringAsFixed(0),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ج.م',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 18,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => Text(
                    '--',
                    style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // بطاقة مواعيد اليوم بتقنية Double-Bezel
        Expanded(
          child: DoubleBezelCard(
            outerRadius: 18.0,
            innerRadius: 15.5,
            outerPadding: const EdgeInsets.all(2.5),
            innerPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مواعيد اليوم',
                      style: TextStyle(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_alt_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalAppts',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required int index,
    required String label,
    required int count,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedFilterIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedFilterIndex = index),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? accentColor.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.12))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.035)
                    : Colors.black.withValues(alpha: 0.025)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.6 : 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? accentColor
                    : theme.hintColor.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : accentColor)
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: isDark ? 0.35 : 0.2)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isDark ? Colors.white : accentColor)
                        : theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BookAppointmentDialog(clinicId: widget.user.clinicId),
            );
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'حجز جديد',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(todayAppointmentsProvider);
          ref.invalidate(todayRevenueProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. شريط الأيام
            AppointmentsCalendarStrip(selectedDate: widget.selectedDate, user: widget.user),
            const SizedBox(height: 14),

            // 2. بطاقة ملخص الإيرادات والمواعيد
            widget.appointmentsAsync.when(
              data: (list) => _buildRevenueSummary(context, ref, list.length),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // 3. أزرار الفلترة الأفقية اللمسية
            widget.appointmentsAsync.when(
              data: (list) {
                final allCount = list.length;
                final waitingCount = list.where((a) => a.status == 'confirmed').length;
                final pendingCount = list.where((a) => a.status == 'pending').length;
                final completedCount = list.where((a) => a.status == 'completed').length;
                final cancelledCount = list.where((a) => a.status.startsWith('cancelled')).length;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill(
                        index: 0,
                        label: 'الكل',
                        count: allCount,
                        icon: Icons.all_inclusive_rounded,
                        accentColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 1,
                        label: 'في الانتظار',
                        count: waitingCount,
                        icon: Icons.hourglass_top_rounded,
                        accentColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 2,
                        label: 'مع الطبيب',
                        count: pendingCount,
                        icon: Icons.person_search_rounded,
                        accentColor: const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 3,
                        label: 'منتهي',
                        count: completedCount,
                        icon: Icons.check_circle_rounded,
                        accentColor: const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        index: 4,
                        label: 'ملغي',
                        count: cancelledCount,
                        icon: Icons.cancel_outlined,
                        accentColor: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // 4. قائمة المواعيد بمسافات Macro-Whitespace وحركات دخول متدرجة
            widget.appointmentsAsync.when(
              data: (appointments) {
                final filtered = appointments.where((a) {
                  if (_selectedFilterIndex == 1) return a.status == 'confirmed';
                  if (_selectedFilterIndex == 2) return a.status == 'pending';
                  if (_selectedFilterIndex == 3) return a.status == 'completed';
                  if (_selectedFilterIndex == 4) return a.status.startsWith('cancelled');
                  return true;
                }).toList();

                // الترتيب الزمني
                filtered.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: DoubleBezelCard(
                        outerRadius: 20,
                        innerRadius: 17.5,
                        outerPadding: const EdgeInsets.all(2.5),
                        innerPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_busy_rounded,
                                size: 38,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'لا توجد مواعيد في هذا القسم',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.titleMedium?.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'يمكنك إضافة موعد جديد بالضغط على زر حجز جديد',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final appt = entry.value;
                    return StaggeredCardEntry(
                      index: index,
                      child: AppointmentCardItem(
                        appointment: appt,
                        clinicId: widget.user.clinicId,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('حدث خطأ: $err', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
