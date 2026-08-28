import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/appointment_model.dart';
import '../../reports/presentation/reports_controller.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'appointments_calendar_strip.dart';
import 'appointment_card_item.dart';

/// العرض المخصص للهاتف لشاشة المواعيد
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

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إيرادات اليوم',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                todayRevenueAsync.when(
                  data: (rev) => Row(
                    children: [
                      Text(
                        rev.toStringAsFixed(0),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('ج.م', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  loading: () => const SizedBox(height: 18, child: LinearProgressIndicator()),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: AppTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مواعيد اليوم',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalAppts',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => BookAppointmentDialog(clinicId: widget.user.clinicId),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('حجز جديد', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
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
            const SizedBox(height: 12),

            // 2. بطاقة ملخص الإيرادات والمواعيد
            widget.appointmentsAsync.when(
              data: (list) => _buildRevenueSummary(context, ref, list.length),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            // 3. أزرار الفلترة الأفقية
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: _selectedFilterIndex == 0,
                    onSelected: (s) => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('في الانتظار'),
                    selected: _selectedFilterIndex == 1,
                    onSelected: (s) => setState(() => _selectedFilterIndex = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('مع الطبيب'),
                    selected: _selectedFilterIndex == 2,
                    onSelected: (s) => setState(() => _selectedFilterIndex = 2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('منتهي'),
                    selected: _selectedFilterIndex == 3,
                    onSelected: (s) => setState(() => _selectedFilterIndex = 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. قائمة المواعيد
            widget.appointmentsAsync.when(
              data: (appointments) {
                final filtered = appointments.where((a) {
                  if (_selectedFilterIndex == 1) return a.status == 'confirmed';
                  if (_selectedFilterIndex == 2) return a.status == 'pending';
                  if (_selectedFilterIndex == 3) return a.status == 'completed';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 48, color: theme.hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد مواعيد في هذا القسم',
                            style: TextStyle(fontSize: 14, color: theme.hintColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered
                      .map((appt) => AppointmentCardItem(
                            appointment: appt,
                            clinicId: widget.user.clinicId,
                          ))
                      .toList(),
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
