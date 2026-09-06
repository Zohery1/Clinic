import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'appointment_card.dart';
import 'desktop/details_pane.dart';

enum _ViewMode { denseList, queueKanban }

/// واجهة المواعيد لسطح المكتب والأجهزة اللوحية
/// مصممة بهندسة سريرية عالية الكثافة مع دعم:
/// 1. شريط تحكم تاريخ وإحصائيات طابور فورية (KPI Ticker)
/// 2. تبديل مرن بين "القائمة المدمجة" و"لوحة طابور المراحل (Kanban)"
/// 3. فحص سريري سريع (Clinical Inspector) قابل للطي
class AppointmentsDesktopView extends ConsumerStatefulWidget {
  final UserModel user;
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  final DateTime selectedDate;

  const AppointmentsDesktopView({
    super.key,
    required this.user,
    required this.appointmentsAsync,
    required this.selectedDate,
  });

  @override
  ConsumerState<AppointmentsDesktopView> createState() =>
      _AppointmentsDesktopViewState();
}

class _AppointmentsDesktopViewState
    extends ConsumerState<AppointmentsDesktopView> {
  AppointmentModel? _selected;
  _ViewMode _viewMode = _ViewMode.denseList;
  String _statusFilter = 'all'; // all, confirmed, pending, completed, cancelled
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() => _searchQuery = '');
  }

  void _goToPrevDay() {
    final cur = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state =
        cur.subtract(const Duration(days: 1));
  }

  void _goToNextDay() {
    final cur = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state =
        cur.add(const Duration(days: 1));
  }

  void _goToToday() {
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
  }

  Future<void> _pickDate() async {
    final cur = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  bool _matchesFilter(AppointmentModel a) {
    // 1. Status filter
    final s = a.status.toLowerCase();
    if (_statusFilter == 'confirmed' && s != 'confirmed') return false;
    if (_statusFilter == 'pending' && s != 'pending') return false;
    if (_statusFilter == 'completed' && s != 'completed') return false;
    if (_statusFilter == 'cancelled' && !s.startsWith('cancelled')) return false;

    // 2. Search query filter
    if (_searchQuery.isEmpty) return true;
    final name = a.patient.fullName.toLowerCase();
    final phone = a.patient.phone?.toLowerCase() ?? '';
    final doctor = a.doctorName?.toLowerCase() ?? '';
    final type = a.appointmentTypeName?.toLowerCase() ?? '';

    return name.contains(_searchQuery) ||
        phone.contains(_searchQuery) ||
        doctor.contains(_searchQuery) ||
        type.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final appointments = widget.appointmentsAsync.value ?? [];

    // مزامنة الموعد المحدد مع أحدث نسخة في Riverpod
    final activeSelected = _selected == null
        ? null
        : appointments.firstWhere(
            (a) => a.id == _selected!.id,
            orElse: () => _selected!,
          );

    final totalCount = appointments.length;
    final waitingCount =
        appointments.where((a) => a.status == 'confirmed').length;
    final inDoctorCount =
        appointments.where((a) => a.status == 'pending').length;
    final completedCount =
        appointments.where((a) => a.status == 'completed').length;
    final cancelledCount =
        appointments.where((a) => a.status.startsWith('cancelled')).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ─── 1. شريط التحكم السريري العلوي (Top Command Bar) ───
              _buildTopCommandBar(
                selectedDate: selectedDate,
                totalCount: totalCount,
                waitingCount: waitingCount,
                inDoctorCount: inDoctorCount,
                completedCount: completedCount,
                cancelledCount: cancelledCount,
              ),
              const SizedBox(height: 10),

              // ─── 2. منطقة العمل الرئيسية ───
              Expanded(
                child: widget.appointmentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => AppErrorState(
                    title: 'تعذر تحميل المواعيد',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(todayAppointmentsProvider),
                  ),
                  data: (_) {
                    if (_viewMode == _ViewMode.queueKanban) {
                      return _buildKanbanView(appointments, activeSelected);
                    }
                    return _buildDenseListView(appointments, activeSelected);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── شريط التحكم العلوي المدمج ───
  Widget _buildTopCommandBar({
    required DateTime selectedDate,
    required int totalCount,
    required int waitingCount,
    required int inDoctorCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateLabel =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // أزرار تصفح التاريخ السريع
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'اليوم السابق',
                visualDensity: VisualDensity.compact,
                onPressed: _goToPrevDay,
              ),
              InkWell(
                onTap: _goToToday,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primarySubtle
                        : AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    'اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.textSecondary(context),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'اليوم التالي',
                visualDensity: VisualDensity.compact,
                onPressed: _goToNextDay,
              ),
              const SizedBox(width: 4),

              // منتقي التاريخ
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // عدادات وإحصائيات الطابور اللحظية (KPI Ticker)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildKpiChip(
                label: 'الكل',
                count: totalCount,
                color: AppColors.primary,
                filterKey: 'all',
              ),
              const SizedBox(width: 6),
              _buildKpiChip(
                label: 'بالانتظار',
                count: waitingCount,
                color: AppColors.warning,
                filterKey: 'confirmed',
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 6),
              _buildKpiChip(
                label: 'مع الطبيب',
                count: inDoctorCount,
                color: AppColors.info,
                filterKey: 'pending',
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(width: 6),
              _buildKpiChip(
                label: 'مكتمل',
                count: completedCount,
                color: AppColors.success,
                filterKey: 'completed',
                icon: Icons.check_circle_rounded,
              ),
              if (cancelledCount > 0) ...[
                const SizedBox(width: 6),
                _buildKpiChip(
                  label: 'ملغي',
                  count: cancelledCount,
                  color: AppColors.danger,
                  filterKey: 'cancelled',
                  icon: Icons.cancel_outlined,
                ),
              ],
            ],
          ),

          // مبدل نمط العرض + زر حجز جديد
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مفتاح تبديل العرض (List vs Kanban)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTab(
                      mode: _ViewMode.denseList,
                      icon: Icons.view_headline_rounded,
                      label: 'قائمة مدمجة',
                    ),
                    _buildViewTab(
                      mode: _ViewMode.queueKanban,
                      icon: Icons.view_kanban_outlined,
                      label: 'طابور المراحل',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // زر حجز جديد
              FilledButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => BookAppointmentDialog(
                      clinicId: widget.user.clinicId,
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'حجز جديد',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiChip({
    required String label,
    required int count,
    required Color color,
    required String filterKey,
    IconData? icon,
  }) {
    final isSelected = _statusFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _statusFilter = isSelected && filterKey != 'all' ? 'all' : filterKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.subtle(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? color : AppColors.textSecondary(context)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary(context),
                height: 1.35,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab({
    required _ViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final active = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? AppColors.primary
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary(context),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── نمط 1: القائمة المدمجة عالية الكثافة (Dense List View) ───
  Widget _buildDenseListView(
    List<AppointmentModel> allAppointments,
    AppointmentModel? activeSelected,
  ) {
    final sorted = [...allAppointments]
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final filtered = sorted.where(_matchesFilter).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الجناح الرئيسي: شريط البحث وقائمة المواعيد المدمجة
        Expanded(
          flex: activeSelected != null ? 6 : 10,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // حقل البحث السريع
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.subtle(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.borderSubtle(context),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: GoogleFonts.cairo(fontSize: 12.5, height: 1.35),
                          decoration: InputDecoration(
                            hintText:
                                'البحث الفوري باسم المريض، رقم الهاتف، الطبيب، أو نوع الكشف...',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textMuted(context),
                              height: 1.35,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 18, color: AppColors.primary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded,
                                        size: 16),
                                    onPressed: _clearSearch,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.subtle(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'العدد المعروض: ${filtered.length}',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // قائمة الكروت المدمجة
                Expanded(
                  child: filtered.isEmpty
                      ? AppEmptyState(
                          icon: _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.event_busy_rounded,
                          title: _searchQuery.isNotEmpty
                              ? 'لا توجد نتائج مطابقة'
                              : 'لا توجد مواعيد لهذا اليوم',
                          message: _searchQuery.isNotEmpty
                              ? 'جرّب البحث بكلمة أو رقم مختلف'
                              : 'اضغط على "حجز جديد" لتسجيل موعد جديد',
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            final appt = filtered[index];
                            return AppointmentCard(
                              appointment: appt,
                              clinicId: widget.user.clinicId,
                              queueIndex: index + 1,
                              isSelected: activeSelected?.id == appt.id,
                              onTap: () {
                                setState(() {
                                  if (_selected?.id == appt.id) {
                                    _selected = null; // Toggle off
                                  } else {
                                    _selected = appt;
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // الجناح الجانبي: لوحة الفحص السريري (Clinical Inspector)
        if (activeSelected != null) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 380,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle(context)),
              ),
              child: DesktopDetailsPane(
                user: widget.user,
                selected: activeSelected,
                onClose: () => setState(() => _selected = null),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── نمط 2: لوحة طابور المراحل التفاعلية (Queue Kanban Lanes) ───
  Widget _buildKanbanView(
    List<AppointmentModel> allAppointments,
    AppointmentModel? activeSelected,
  ) {
    final waiting = allAppointments
        .where((a) => a.status == 'confirmed' && _matchesFilter(a))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    final inDoctor = allAppointments
        .where((a) => a.status == 'pending' && _matchesFilter(a))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    final completed = allAppointments
        .where((a) => a.status == 'completed' && _matchesFilter(a))
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final isCompactDesktop = totalWidth < 1400;
        final detailsWidth = isCompactDesktop ? 340.0 : 360.0;
        final hasDetails = activeSelected != null;

        // Ensure 3 lanes never get squashed below 260px (min 3 * 260 + 20 = 800px)
        final availableForLanes =
            hasDetails ? (totalWidth - detailsWidth - 10) : totalWidth;
        final needsHorizontalScroll = availableForLanes < 850;

        Widget buildLanesRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مسار 1: في الانتظار
              needsHorizontalScroll
                  ? SizedBox(
                      width: 260,
                      child: _buildKanbanLane(
                        title: 'طابور الانتظار',
                        subtitle: 'مرضى جاهزون للدخول',
                        count: waiting.length,
                        color: AppColors.warning,
                        icon: Icons.hourglass_top_rounded,
                        items: waiting,
                        activeSelected: activeSelected,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        title: 'طابور الانتظار',
                        subtitle: 'مرضى جاهزون للدخول',
                        count: waiting.length,
                        color: AppColors.warning,
                        icon: Icons.hourglass_top_rounded,
                        items: waiting,
                        activeSelected: activeSelected,
                      ),
                    ),
              const SizedBox(width: 10),

              // مسار 2: مع الطبيب
              needsHorizontalScroll
                  ? SizedBox(
                      width: 260,
                      child: _buildKanbanLane(
                        title: 'مع الطبيب',
                        subtitle: 'جلسات الفحص الجارية',
                        count: inDoctor.length,
                        color: AppColors.info,
                        icon: Icons.medical_services_outlined,
                        items: inDoctor,
                        activeSelected: activeSelected,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        title: 'مع الطبيب',
                        subtitle: 'جلسات الفحص الجارية',
                        count: inDoctor.length,
                        color: AppColors.info,
                        icon: Icons.medical_services_outlined,
                        items: inDoctor,
                        activeSelected: activeSelected,
                      ),
                    ),
              const SizedBox(width: 10),

              // مسار 3: مكتمل اليوم
              needsHorizontalScroll
                  ? SizedBox(
                      width: 260,
                      child: _buildKanbanLane(
                        title: 'مكتمل اليوم',
                        subtitle: 'تم الكشف وإنهاء الزيارة',
                        count: completed.length,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                        items: completed,
                        activeSelected: activeSelected,
                      ),
                    )
                  : Expanded(
                      child: _buildKanbanLane(
                        title: 'مكتمل اليوم',
                        subtitle: 'تم الكشف وإنهاء الزيارة',
                        count: completed.length,
                        color: AppColors.success,
                        icon: Icons.check_circle_rounded,
                        items: completed,
                        activeSelected: activeSelected,
                      ),
                    ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: needsHorizontalScroll
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 800,
                        child: buildLanesRow(),
                      ),
                    )
                  : buildLanesRow(),
            ),

            // فحص جانبي إذا تم تحديد موعد
            if (activeSelected != null) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: detailsWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: DesktopDetailsPane(
                    user: widget.user,
                    selected: activeSelected,
                    onClose: () => setState(() => _selected = null),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKanbanLane({
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required IconData icon,
    required List<AppointmentModel> items,
    required AppointmentModel? activeSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        children: [
          // رأس المسار
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        height: 1.35,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: AppColors.textSecondary(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الكروت داخل المسار
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'لا يوجد مرضى في هذه المرحلة حالياً',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textMuted(context),
                          height: 1.35,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final appt = items[i];
                      return AppointmentCard(
                        appointment: appt,
                        clinicId: widget.user.clinicId,
                        queueIndex: i + 1,
                        isSelected: activeSelected?.id == appt.id,
                        onTap: () {
                          setState(() {
                            if (_selected?.id == appt.id) {
                              _selected = null;
                            } else {
                              _selected = appt;
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
