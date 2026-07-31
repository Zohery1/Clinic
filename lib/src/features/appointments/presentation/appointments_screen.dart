import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/login_controller.dart';
import '../domain/appointment_model.dart';
import 'appointments_controller.dart';
import '../data/appointment_repository.dart';
import '../../reports/presentation/reports_controller.dart';
import 'book_appointment_dialog.dart';
import 'visit_notes_dialog.dart';
import '../../patients/data/patient_repository.dart';
import '../../patients/domain/patient_model.dart';
import 'widgets/queue_board.dart';
import 'widgets/queue_card.dart';
import 'widgets/admission_confirmation_sheet.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../../dashboard/domain/notification_model.dart';

/// شاشة المواعيد — مطابقة لتصميم Stitch
/// شريط أيام أفقي + بطاقات مواعيد بتأثير waterfall
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _selectedMobileTab = 0;

  String _getShortDayName(String label) {
    if (label.startsWith('ال')) {
      return label.substring(2);
    }
    return label;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF3B82F6); // Blue (مع الطبيب)
      case 'confirmed':
        return const Color(0xFFF59E0B); // Orange (في الانتظار)
      case 'completed':
        return const Color(0xFF10B981); // Green (منتهي)
      case 'cancelled':
      case 'cancelled_by_patient':
      case 'cancelled_by_clinic':
        return const Color(0xFFEF4444); // Red (ملغي)
      default:
        return const Color(0xFFF59E0B); // Orange (في الانتظار)
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'مع الطبيب';
      case 'confirmed':
        return 'في الانتظار';
      case 'completed':
        return 'منتهي';
      case 'cancelled':
      case 'cancelled_by_clinic':
        return 'ملغي (عيادة)';
      case 'cancelled_by_patient':
        return 'عدم حضور / ملغي (مريض)';
      default:
        return 'في الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(todayAppointmentsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (user == null) {
      return Center(
        child: Text('يرجى تسجيل الدخول أولاً',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
      );
    }

    // Watch notifications
    final notificationsState = ref.watch(notificationsProvider);
    final unreadCount = notificationsState.notifications.where((n) => !n.isRead).length;

    if (isDesktop) {
      return _buildDesktopLayout(context, ref, user, appointmentsAsync, selectedDate);
    } else {
      return _buildMobileLayout(context, ref, user, appointmentsAsync, selectedDate, unreadCount);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else {
      return 'منذ ${diff.inDays} يوم';
    }
  }

  void _showNotificationsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(notificationsProvider);
          final notifier = ref.read(notificationsProvider.notifier);
          final theme = Theme.of(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.notifications_active_rounded,
                            color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'التنبيهات والإشعارات',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  if (state.notifications.any((n) => !n.isRead))
                    TextButton(
                      onPressed: () {
                        notifier.markAllAsRead();
                      },
                      child: Text(
                        'قراءة الكل',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: state.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : state.notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 40, color: theme.hintColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    'لا توجد إشعارات حالياً',
                                    style: TextStyle(
                                        color: theme.hintColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: state.notifications.length,
                            separatorBuilder: (_, __) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final notification = state.notifications[index];
                              IconData icon = Icons.info_outline_rounded;
                              Color color = theme.colorScheme.primary;
                              
                              if (notification.title == 'حجز جديد') {
                                icon = Icons.calendar_today_rounded;
                                color = AppTheme.success;
                              } else if (notification.title == 'إضافة خدمة طبية') {
                                icon = Icons.medical_services_outlined;
                                color = AppTheme.completed;
                              }

                              return InkWell(
                                onTap: () {
                                  if (!notification.isRead) {
                                    notifier.markAsRead(notification.id);
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: color, size: 18),
                                          ),
                                          if (!notification.isRead)
                                            Positioned(
                                              top: 0,
                                              right: 0,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.error,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notification.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: theme.textTheme.bodyLarge?.color,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notification.body,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.textTheme.bodyMedium?.color,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTimeAgo(notification.createdAt),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: theme.hintColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── Desktop Layout (2/3 area inside dashboard) ───
  // ═══════════════════════════════════════════════
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    DateTime selectedDate,
  ) {
    final todayFormatted =
        intl.DateFormat('d MMMM، yyyy', 'ar').format(selectedDate);
    final dayName = intl.DateFormat('EEEE', 'ar').format(selectedDate);

    return Column(
      children: [
        // ─── Horizontal Calendar Strip ───
        _buildCalendarStrip(context, ref, selectedDate, dayName, todayFormatted, user),
        const SizedBox(height: 16),
        // ─── Queue Board ───
        Expanded(
          child: appointmentsAsync.when(
            data: (appointments) => appointments.isEmpty
                ? _buildEmptyState(context)
                : QueueBoard(appointments: appointments, clinicId: user.clinicId),
            loading: () => ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: 4,
              itemBuilder: (_, __) => _buildSkeletonCard(context),
            ),
            error: (err, _) => Center(
              child: Text('حدث خطأ في تحميل البيانات',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        ),
      ],
    );
  }


  // ═══════════════════════════════════════════════
  // ─── Calendar Strip — Stitch: 7 أيام + أيقونة تقويم ───
  // ═══════════════════════════════════════════════
  Widget _buildCalendarStrip(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    String dayName,
    String formattedDate,
    dynamic user,
  ) {
    // Generate 7 days: Sat through Fri
    final now = DateTime.now();
    // Find the Saturday of this week
    final diff = now.weekday >= DateTime.saturday ? now.weekday - DateTime.saturday : now.weekday + 7 - DateTime.saturday;
    final saturday = now.subtract(Duration(days: diff));
    final days = List.generate(7, (i) => saturday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          // Calendar icon button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024, 1, 1),
                  lastDate: DateTime(2028, 12, 31),
                );
                if (picked != null) {
                  ref.read(selectedDateProvider.notifier).state =
                      DateTime(picked.year, picked.month, picked.day);
                }
              },
              icon: Icon(Icons.calendar_month_rounded,
                  color: Theme.of(context).colorScheme.primary, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: days.map((day) {
                final isSelected = DateUtils.isSameDay(selectedDate, day);
                final isFriday = false;
                final dayLabel = intl.DateFormat('E', 'ar').format(day);
                final dayNum = intl.DateFormat('d').format(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(day.year, day.month, day.day);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getShortDayName(dayLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayNum,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : isFriday
                                      ? Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.5)
                                      : Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          if (MediaQuery.of(context).size.width >= 1150) ...[
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'مواعيد $dayName',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مواعيد مجدولة لليوم',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'اضغط على "حجز جديد" لإضافة موعد',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 16,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileRevenueSummary(BuildContext context, WidgetRef ref, AsyncValue<List<AppointmentModel>> appointmentsAsync) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: AppTheme.cardDecoration(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إيرادات اليوم',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      todayRevenueAsync.when(
                        data: (revenue) => Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              revenue.toStringAsFixed(0),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'ج.م',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        loading: () => Container(width: 60, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08), borderRadius: BorderRadius.circular(4))),
                        error: (_, __) => const Text('--', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981)).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trending_up_rounded, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF10B981), size: 18),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مواعيد اليوم',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      appointmentsAsync.when(
                        data: (list) => Text(
                          '${list.length}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        loading: () => Container(width: 40, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08), borderRadius: BorderRadius.circular(4))),
                        error: (_, __) => const Text('--', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    DateTime selectedDate,
    int unreadCount,
  ) {
    final actualTodayFormatted =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BookAppointmentDialog(clinicId: user?.clinicId ?? ''),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
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
            ref.invalidate(monthRevenueProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateTime.now().hour < 12 ? 'صباح الخير' : 'مساء الخير'}، ${user.fullName.split(' ').first}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                actualTodayFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bell notification button for mobile
                        Stack(
                          children: [
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _showNotificationsDialog(context, ref),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ─── إحصائيات سريعة (الايراد اليومي والمواعيد) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildMobileRevenueSummary(context, ref, appointmentsAsync),
                ),
              ),
              // ─── شريط اختيار التاريخ (موبايل) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 58,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              final day = DateTime.now()
                                  .subtract(const Duration(days: 3))
                                  .add(Duration(days: index));
                              final isSelected =
                                  DateUtils.isSameDay(selectedDate, day);
                              final dayName =
                                  intl.DateFormat('E', 'ar').format(day);
                              final dayNumber = intl.DateFormat('d').format(day);

                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(selectedDateProvider.notifier)
                                      .state = DateTime(
                                      day.year, day.month, day.day);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 50,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNumber,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context).textTheme.bodyLarge?.color,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        height: 58,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.calendar_month_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 20),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024, 1, 1),
                              lastDate: DateTime(2028, 12, 31),
                            );
                            if (picked != null) {
                              ref.read(selectedDateProvider.notifier).state =
                                  DateTime(
                                      picked.year, picked.month, picked.day);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── عنوان القائمة ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'مواعيد اليوم',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                BookAppointmentDialog(clinicId: user.clinicId),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('حجز جديد',
                            style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── تبويبات التصفية (الانتظار، مع الطبيب، مكتمل، ملغي) ───
              appointmentsAsync.when(
                data: (appointments) => _buildMobileFilterTabs(
                  context,
                  appointments,
                  _selectedMobileTab,
                  (index) => setState(() => _selectedMobileTab = index),
                ),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              // ─── قائمة المواعيد ───
              _buildMobileAppointmentsList(
                  context, appointmentsAsync, ref, user.clinicId, _selectedMobileTab),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        // duplicate floatingActionButton removed
      ),
    );
  }

  Widget _buildMobileFilterTabs(
    BuildContext context,
    List<AppointmentModel> appointments,
    int selectedTab,
    void Function(int) onTabSelected,
  ) {
    final waitingCount = appointments.where((a) => a.status == 'confirmed').length;
    final withDoctorCount = appointments.where((a) => a.status == 'pending').length;
    final completedCount = appointments.where((a) => a.status == 'completed').length;
    final cancelledCount = appointments.where((a) => a.status.startsWith('cancelled')).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [

              _buildFilterChip(context, 0, 'الانتظار', waitingCount, const Color(0xFFF59E0B), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 1, 'مع الطبيب', withDoctorCount, const Color(0xFF3B82F6), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 2, 'مكتمل', completedCount, const Color(0xFF10B981), selectedTab, onTabSelected),
              const SizedBox(width: 8),
              _buildFilterChip(context, 3, 'ملغي', cancelledCount, const Color(0xFFEF4444), selectedTab, onTabSelected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    int index,
    String label,
    int count,
    Color color,
    int selectedTab,
    void Function(int) onTabSelected,
  ) {
    final isSelected = selectedTab == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(isSelected ? 1.0 : 0.5), width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAppointmentsList(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> appointmentsAsync,
    WidgetRef ref,
    String clinicId,
    int selectedTab,
  ) {
    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState(context));
        }

        // تقسيم المواعيد لأربع قوائم حسب الحالة
        final waiting = appointments
            .where((a) => a.status == 'confirmed')
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

        final withDoctor = appointments
            .where((a) => a.status == 'pending')
            .toList();

        final completed = appointments
            .where((a) => a.status == 'completed')
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        final cancelled = appointments
            .where((a) => a.status.startsWith('cancelled'))
            .toList()
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        List<AppointmentModel> currentList;
        QueueLaneType laneType;
        switch (selectedTab) {
          case 0:
            currentList = waiting;
            laneType = QueueLaneType.waiting;
            break;
          case 1:
            currentList = withDoctor;
            laneType = QueueLaneType.withDoctor;
            break;
          case 2:
            currentList = completed;
            laneType = QueueLaneType.completed;
            break;
          case 3:
            currentList = cancelled;
            laneType = QueueLaneType.cancelled;
            break;
          default:
            currentList = waiting;
            laneType = QueueLaneType.waiting;
        }

        if (currentList.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 48, color: Theme.of(context).hintColor.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد مواعيد في هذا القسم',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final appt = currentList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QueueCard(
                    appointment: appt,
                    laneType: laneType,
                    queuePosition: laneType == QueueLaneType.waiting ? index + 1 : null,
                    clinicId: clinicId,
                    withDoctorCount: withDoctor.length,
                  ),
                );
              },
              childCount: currentList.length,
            ),
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => _buildSkeletonCard(context),
            childCount: 4,
          ),
        ),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('حدث خطأ في تحميل البيانات',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════
// ─── بطاقة الموعد — مطابقة لـ Stitch بتأثير waterfall ───
// ═══════════════════════════════════════════════
class _StaggeredAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel appointment;
  final int index;
  final String clinicId;
  final Color Function(String) getStatusColor;
  final String Function(String) translateStatus;

  const _StaggeredAppointmentCard({
    required this.appointment,
    required this.index,
    required this.clinicId,
    required this.getStatusColor,
    required this.translateStatus,
  });

  @override
  ConsumerState<_StaggeredAppointmentCard> createState() =>
      _StaggeredAppointmentCardState();
}

class _StaggeredAppointmentCardState
    extends ConsumerState<_StaggeredAppointmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    // Stagger delay: 100ms per item
    Future.delayed(Duration(milliseconds: (widget.index + 1) * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;
    final appointment = widget.appointment;
    final formattedTime = intl.DateFormat('hh:mm a')
        .format(appointment.appointmentDate.toLocal());
    final statusColor = widget.getStatusColor(appointment.status);
    final statusText = widget.translateStatus(appointment.status);
    final isCompleted = appointment.status == 'completed' || appointment.status.startsWith('cancelled');

    // جلب رقم ملف المريض ديناميكياً
    final patientsAsync = ref.watch(patientsListProvider(widget.clinicId));
    final patients = patientsAsync.value ?? [];
    final sortedPatients = List<PatientModel>.from(patients)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final patientIndex = sortedPatients.indexWhere((p) => p.id == appointment.patientId);
    final fileNo = patientIndex != -1 ? '${patientIndex + 1}' : '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedOpacity(
            opacity: isCompleted ? 0.6 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ─── Row 1: Avatar + Info + Status ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          // Removed border here
                        ),
                        child: Center(
                          child: Text(
                            appointment.patient.fullName.isNotEmpty
                                ? appointment.patient.fullName[0].toUpperCase()
                                : '؟',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + visit type + time + phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + badge
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _capitalizeName(appointment.patient.fullName),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Theme.of(context).textTheme.titleMedium?.color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (fileNo.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#$fileNo',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    appointment.appointmentTypeName ?? 'كشف جديد',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Time + Phone
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded,
                                    size: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                                if (appointment.patient.phone != null &&
                                    appointment.patient.phone!.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Icon(Icons.phone_rounded,
                                      size: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    appointment.patient.phone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                           if (appointment.priceCharged != null) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${appointment.priceCharged!.toStringAsFixed(0)} ج.م',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  // ─── Divider + Action Buttons ───
                  if (!isCompleted) ...[
                    const SizedBox(height: 10),
                    Divider(color: Theme.of(context).dividerColor, height: 1),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (appointment.status == 'pending') ...[
                          // زر التقرير الطبي وإضافة الخدمات (يظهر فقط مع الطبيب)
                          _buildPrimaryActionButton(
                            label: isDoctor ? 'التقرير الطبي والخدمات' : 'التقرير الطبي',
                            icon: isDoctor ? Icons.medical_information_outlined : Icons.description_outlined,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => VisitNotesDialog(
                                  clinicId: widget.clinicId,
                                  appointmentId: appointment.id,
                                  patientId: appointment.patientId,
                                  patientName: appointment.patient.fullName,
                                ),
                              );
                            },
                          ),
                          // زر إنهاء الكشف (منتهي)
                          _buildSecondaryActionButton(
                            label: 'إنهاء الكشف (منتهي)',
                            onTap: () => _updateStatus('completed'),
                          ),
                        ] else ...[
                          // زر بدء الكشف (مع الطبيب) - يحول الحالة إلى pending
                          _buildPrimaryActionButton(
                            label: 'بدء الكشف (مع الطبيب)',
                            icon: Icons.play_arrow_rounded,
                            onTap: () => _updateStatus('pending'),
                          ),
                        ],
                        // زر إلغاء الموعد (متاح دائماً طالما لم يكتمل/يلغى)
                        _buildDangerActionButton(
                          label: 'إلغاء الموعد',
                          onTap: () => _showCancelOptionsSheet(context, ref),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateStatus(String status) async {
    final previousStatus = widget.appointment.status;
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .updateAppointmentStatus(widget.appointment.id, status);
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);
      ref.invalidate(monthRevenueProvider);

      if (context.mounted) {
        final label = status == 'pending'
            ? 'تم نقل المريض للطبيب'
            : status == 'completed'
                ? 'تم إنهاء الكشف'
                : 'تم إلغاء الموعد';

        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            content: Text(label),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'تراجع',
              onPressed: () async {
                await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(widget.appointment.id, previousStatus);
                ref.invalidate(todayAppointmentsProvider);
                ref.invalidate(todayRevenueProvider);
                ref.invalidate(monthRevenueProvider);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
            content: Text('حدث خطأ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showCancelOptionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'سبب الإلغاء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAdmissionSheet(context, ref, 'cancelled_by_patient');
                },
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('المريض لم يحضر / اعتذر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAdmissionSheet(context, ref, 'cancelled_by_clinic');
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء من قبل العيادة / الطبيب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdmissionSheet(BuildContext context, WidgetRef ref, String targetStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdmissionConfirmationSheet(
        appointment: widget.appointment,
        targetStatus: targetStatus,
        onConfirm: () => _updateStatus(targetStatus),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Theme.of(context).colorScheme.onPrimary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
            // Removed border here
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
