import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/routing/routing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/utils/doctor_utils.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../clinics/domain/branch_model.dart';
import '../../../clinics/presentation/clinics_controller.dart';
import '../../data/appointment_repository.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import 'appointment_card.dart';
import 'desktop/appointments_kanban_view.dart';
import 'desktop/details_pane.dart';

enum _ViewMode { denseList, queueKanban }

/// واجهة سطح المكتب السريرية عالية الكثافة للمواعيد (High-Density Clinical Bento Deck).
/// مصممة وفق أسلوب Bento المضغوط والمريح بصرياً:
/// 1. Bento Executive Hero Card: شريط تحكم مدمج بالتاريخ وفلاتر الأطباء والفروع وزر الحجز.
/// 2. 5 بطاقات Bento KPI تفاعلية: الكل، في الانتظار، مع الطبيب، مكتمل، وملغي (فلترة فورية).
/// 3. مساحة عمل تشغيلية ثنائية (3:1 Workspace):
///    - العمود الرئيسي: شريط البحث، مبدل العرض (قائمة مدمجة / طابور المراحل)، والقائمة اليومية.
///    - العمود الجانبي: لوحة الفحص التفصيلية أو تقويم أحمال الأسبوع وتوزيع أطباء العيادة.
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
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
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
    final now = DateTime.now();
    ref.read(selectedDateProvider.notifier).state =
        DateTime(now.year, now.month, now.day);
  }

  bool _matchesFilter(AppointmentModel a) {
    // 1. تصفية الحالة
    final s = a.status.toLowerCase();
    if (_statusFilter == 'confirmed' && s != 'confirmed') return false;
    if (_statusFilter == 'pending' && s != 'pending') return false;
    if (_statusFilter == 'completed' && s != 'completed') return false;
    if (_statusFilter == 'cancelled' && !s.startsWith('cancelled')) return false;

    // 2. البحث النصي السريع
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

  String _formatArabicDate(DateTime date) {
    try {
      return intl.DateFormat('EEEE، d MMMM y', 'ar').format(date);
    } catch (_) {
      return '${date.year}/${date.month}/${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final appointments = widget.appointmentsAsync.value ?? [];

    final activeSelected = _selected == null
        ? null
        : appointments.where((a) => a.id == _selected!.id).firstOrNull;

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
      child: Material(
        color: AppColors.canvas(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. ترويسة Bento التنفيذية المدمجة (Bento Executive Hero Card) ───
              _buildExecutiveHeroCard(
                context: context,
                selectedDate: selectedDate,
                totalCount: totalCount,
                waitingCount: waitingCount,
              ),

              const SizedBox(height: 10),

              // ─── 2. صف مؤشرات الأداء Bento KPI الخماسي (5 بطاقات تفاعلية) ───
              _buildBentoKpiRow(
                context: context,
                totalCount: totalCount,
                waitingCount: waitingCount,
                inDoctorCount: inDoctorCount,
                completedCount: completedCount,
                cancelledCount: cancelledCount,
              ),

              const SizedBox(height: 10),

              // ─── 3. مساحة العمل التشغيلية ثنائية الأعمدة (Workspace) ───
              widget.appointmentsAsync.when(
                loading: () => Container(
                  height: 350,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: const CircularProgressIndicator(),
                ),
                error: (e, _) => Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: AppErrorState(
                    title: 'تعذر تحميل المواعيد',
                    message: e.toString(),
                    onRetry: () => ref.invalidate(todayAppointmentsProvider),
                  ),
                ),
                data: (_) => _buildTwoColumnWorkspace(
                  context: context,
                  appointments: appointments,
                  activeSelected: activeSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. ترويسة Bento التنفيذية المدمجة (Bento Executive Hero Card)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExecutiveHeroCard({
    required BuildContext context,
    required DateTime selectedDate,
    required int totalCount,
    required int waitingCount,
  }) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(selectedDate, now);
    final bg = AppColors.surface(context);
    final borderColor = AppColors.borderSubtle(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;

          // معلومات التاريخ والحالة التشغيلية
          final dateInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatArabicDate(selectedDate),
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color:
                                isToday ? AppColors.success : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isToday ? 'طابور اليوم نشط' : 'جدول تاريخ محدد',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isToday ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDoctorFilterChip(context),
                  const SizedBox(width: 6),
                  _buildBranchFilterChip(context),
                ],
              ),
            ],
          );

          // كتلة التنقل السريع بين الأيام وزر الحجز
          final actionCluster = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أزرار التنقل: السابق - اليوم - التالي
              Container(
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: Border.all(color: AppColors.borderSubtle(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 16),
                      tooltip: 'اليوم السابق',
                      visualDensity: VisualDensity.compact,
                      onPressed: _goToPrevDay,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                    InkWell(
                      onTap: _goToToday,
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primarySubtle
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 16),
                      tooltip: 'اليوم التالي',
                      visualDensity: VisualDensity.compact,
                      onPressed: _goToNextDay,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // زر اختيار تاريخ محدد من التقويم
              Container(
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: Border.all(color: AppColors.borderSubtle(context)),
                ),
                child: IconButton(
                  tooltip: 'اختيار تاريخ محدد',
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                      locale: const Locale('ar'),
                    );
                    if (picked != null) {
                      ref.read(selectedDateProvider.notifier).state =
                          DateTime(picked.year, picked.month, picked.day);
                    }
                  },
                ),
              ),

              const SizedBox(width: 8),

              // زر الحجز المباشر المدمج
              FilledButton.icon(
                onPressed: () {
                  AppNavigation.showBookAppointment(
                    context,
                    clinicId: widget.user.clinicId,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'حجز جديد',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: const Size(80, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateInfo,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    actionCluster,
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: dateInfo),
              const SizedBox(width: 10),
              actionCluster,
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. صف مؤشرات الأداء Bento KPI الخماسي المدمج (5 بطاقات تفاعلية)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBentoKpiRow({
    required BuildContext context,
    required int totalCount,
    required int waitingCount,
    required int inDoctorCount,
    required int completedCount,
    required int cancelledCount,
  }) {
    final progressRatio =
        totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    final cards = <Widget>[
      _BentoAppointmentKpiTile(
        title: 'الكل',
        value: '$totalCount',
        subtitle: 'حجوزات مسجلة',
        icon: Icons.event_note_rounded,
        accentColor: AppColors.primary,
        bgTint: AppColors.primarySubtle,
        isSelected: _statusFilter == 'all',
        onTap: () => setState(() => _statusFilter = 'all'),
      ),
      _BentoAppointmentKpiTile(
        title: 'في الانتظار',
        value: '$waitingCount',
        subtitle: waitingCount > 0 ? 'في صالة الانتظار' : 'لا يوجد انتظار',
        icon: Icons.hourglass_top_rounded,
        accentColor: AppColors.warning,
        bgTint: AppColors.warningSubtle,
        isSelected: _statusFilter == 'confirmed',
        onTap: () => setState(() {
          _statusFilter = _statusFilter == 'confirmed' ? 'all' : 'confirmed';
        }),
      ),
      _BentoAppointmentKpiTile(
        title: 'قيد الكشف',
        value: '$inDoctorCount',
        subtitle: inDoctorCount > 0 ? 'داخل غرفة الفحص' : 'العيادة جاهزة',
        icon: Icons.medical_services_outlined,
        accentColor: AppColors.info,
        bgTint: AppColors.infoSubtle,
        isSelected: _statusFilter == 'pending',
        onTap: () => setState(() {
          _statusFilter = _statusFilter == 'pending' ? 'all' : 'pending';
        }),
      ),
      _BentoAppointmentKpiTile(
        title: 'مكتمل',
        value: '$completedCount',
        subtitle: totalCount > 0
            ? '${(progressRatio * 100).toInt()}% من كشوفات اليوم'
            : 'لا توجد كشوفات',
        icon: Icons.check_circle_outline_rounded,
        accentColor: AppColors.success,
        bgTint: AppColors.successSubtle,
        progress: progressRatio,
        isSelected: _statusFilter == 'completed',
        onTap: () => setState(() {
          _statusFilter = _statusFilter == 'completed' ? 'all' : 'completed';
        }),
      ),
      _BentoAppointmentKpiTile(
        title: 'ملغي',
        value: '$cancelledCount',
        subtitle: cancelledCount > 0 ? 'اعتذار أو إلغاء' : 'لا توجد إلغاءات',
        icon: Icons.cancel_outlined,
        accentColor: AppColors.danger,
        bgTint: AppColors.dangerSubtle,
        isSelected: _statusFilter == 'cancelled',
        onTap: () => setState(() {
          _statusFilter = _statusFilter == 'cancelled' ? 'all' : 'cancelled';
        }),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 960) {
          return Row(
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        }

        // شاشات أصغر: شبكة مرنة
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cards.map((card) {
            final cardWidth = width >= 600 ? (width - 18) / 3 : (width - 12) / 2;
            return SizedBox(
              width: cardWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. مساحة العمل التشغيلية ثنائية الأعمدة (Workspace)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTwoColumnWorkspace({
    required BuildContext context,
    required List<AppointmentModel> appointments,
    required AppointmentModel? activeSelected,
  }) {
    final sorted = [...appointments]
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    final filtered = sorted.where(_matchesFilter).toList();
    final width = MediaQuery.of(context).size.width;
    final isStacked = width < 1100 || _viewMode == _ViewMode.queueKanban;

    if (_viewMode == _ViewMode.queueKanban) {
      return _buildPrimaryWorkspaceCard(
        context: context,
        filteredAppointments: filtered,
        activeSelected: activeSelected,
      );
    }

    if (isStacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPrimaryWorkspaceCard(
            context: context,
            filteredAppointments: filtered,
            activeSelected: activeSelected,
          ),
          const SizedBox(height: 10),
          _buildSecondaryOpsColumn(
            context: context,
            allAppointments: appointments,
            activeSelected: activeSelected,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العمود الرئيسي (طابور المواعيد والكانبان)
        Expanded(
          flex: 3,
          child: _buildPrimaryWorkspaceCard(
            context: context,
            filteredAppointments: filtered,
            activeSelected: activeSelected,
          ),
        ),
        const SizedBox(width: 10),
        // العمود الجانبي المدمج (توزيع الأطباء ولوحة الفحص)
        SizedBox(
          width: 310,
          child: _buildSecondaryOpsColumn(
            context: context,
            allAppointments: appointments,
            activeSelected: activeSelected,
          ),
        ),
      ],
    );
  }

  // ─── كرت مساحة العمل الرئيسية (Primary Workspace Card) ───
  Widget _buildPrimaryWorkspaceCard({
    required BuildContext context,
    required List<AppointmentModel> filteredAppointments,
    required AppointmentModel? activeSelected,
  }) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط أدوات البحث ومبدل النمط
          Row(
            children: [
              // حقل البحث السريع المدمج
              Expanded(
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.subtle(context),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    border: Border.all(color: AppColors.borderSubtle(context)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.cairo(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'بحث سريع بالاسم، الهاتف، أو الطبيب...',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.textMuted(context),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 14),
                              onPressed: _clearSearch,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // مبدل نمط العرض (قائمة مدمجة / طابور المراحل)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.subtle(context),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  border: Border.all(color: AppColors.borderSubtle(context)),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewTab(
                      mode: _ViewMode.denseList,
                      icon: Icons.format_list_bulleted_rounded,
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
            ],
          ),

          const SizedBox(height: 8),
          Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderSubtle(context)),
          const SizedBox(height: 8),

          // محتوى المواعيد (Kanban أو Dense List)
          if (_viewMode == _ViewMode.queueKanban)
            SizedBox(
              height: 560,
              child: _buildKanbanWorkspace(
                  filteredAppointments, activeSelected),
            )
          else if (filteredAppointments.isEmpty)
            Container(
              height: 340,
              alignment: Alignment.center,
              child: _buildBentoEmptyState(isToday: isToday),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAppointments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (ctx, index) {
                final appt = filteredAppointments[index];
                final isSelected = activeSelected?.id == appt.id;
                return AppointmentCard(
                  key: ValueKey(appt.id),
                  appointment: appt,
                  clinicId: widget.user.clinicId,
                  queueIndex: index + 1,
                  isSelected: isSelected,
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
        ],
      ),
    );
  }

  // ─── العمود الجانبي للعمليات والتقويم (Secondary Ops Column) ───
  Widget _buildSecondaryOpsColumn({
    required BuildContext context,
    required List<AppointmentModel> allAppointments,
    required AppointmentModel? activeSelected,
  }) {
    if (activeSelected != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.borderSubtle(context), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: DesktopDetailsPane(
          user: widget.user,
          selected: activeSelected,
          onClose: () => setState(() => _selected = null),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. تقويم الأسبوع المصغر
        _buildWeeklyMiniCalendarCard(context),

        const SizedBox(height: 10),

        // 2. توزيع طابور الأطباء
        _buildDoctorQueueCard(context, allAppointments),

        const SizedBox(height: 10),

        // 3. إجراءات سريعة
        _buildQuickOperationsCard(context),
      ],
    );
  }

  // ─── كرت تقويم الأسبوع المصغر (Weekly Mini Calendar Card) ───
  Widget _buildWeeklyMiniCalendarCard(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();

    final diff = selectedDate.weekday >= DateTime.saturday
        ? selectedDate.weekday - DateTime.saturday
        : selectedDate.weekday + 7 - DateTime.saturday;
    final weekSaturday = selectedDate.subtract(Duration(days: diff));
    final days = List.generate(7, (i) => weekSaturday.add(Duration(days: i)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'تقويم الأسبوع',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: days.map((day) {
              final isDaySelected = DateUtils.isSameDay(selectedDate, day);
              final isDayToday = DateUtils.isSameDay(now, day);
              final dayLabel = intl.DateFormat('E', 'ar').format(day);
              final dayNum = intl.DateFormat('d').format(day);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state =
                        DateTime(day.year, day.month, day.day);
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isDaySelected
                          ? AppColors.primary
                          : (isDayToday
                              ? AppColors.primarySubtle
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isDayToday && !isDaySelected
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayLabel.startsWith('ال')
                              ? dayLabel.substring(2)
                              : dayLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDaySelected
                                ? Colors.white
                                : AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayNum,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDaySelected
                                ? Colors.white
                                : AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── كرت توزيع أحمال الأطباء (Doctor Queue Card) ───
  Widget _buildDoctorQueueCard(
    BuildContext context,
    List<AppointmentModel> allAppointments,
  ) {
    final doctorsAsync =
        ref.watch(clinicDoctorsProvider(widget.user.clinicId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'طاقم الأطباء اليوم',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          doctorsAsync.when(
            data: (doctors) {
              if (doctors.isEmpty) {
                return Text(
                  'لا يوجد أطباء مسجلون في العيادة',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                );
              }

              return Column(
                children: doctors.take(4).map((doc) {
                  final docAppts = allAppointments
                      .where(
                          (a) => a.doctorName?.trim() == doc.fullName.trim())
                      .toList();
                  final waiting =
                      docAppts.where((a) => a.status == 'confirmed').length;
                  final completed =
                      docAppts.where((a) => a.status == 'completed').length;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.doctorColor(doc.id),
                          child: Text(
                            doc.fullName.isNotEmpty
                                ? doc.fullName.substring(0, 1)
                                : 'ط',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            DoctorUtils.formatTitle(doc.fullName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.subtle(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$waiting انتظار • $completed مكتمل',
                            style: GoogleFonts.cairo(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── كرت الإجراءات السريعة (Quick Operations Card) ───
  Widget _buildQuickOperationsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                'إجراءات سريعة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              AppNavigation.showBookAppointment(
                context,
                clinicId: widget.user.clinicId,
              );
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
            label: Text(
              'حجز كشف جديد',
              style: GoogleFonts.cairo(
                  fontSize: 11, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xs)),
            ),
          ),
          const SizedBox(height: 5),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(todayAppointmentsProvider);
              ClinicToast.showSuccess(
                  context, 'تم تحديث طابور المواعيد');
            },
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(
              'تحديث الطابور',
              style: GoogleFonts.cairo(
                  fontSize: 11, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.xs)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── كرت الحالة الفارغة Bento Empty State ───
  Widget _buildBentoEmptyState({required bool isToday}) {
    final isSearch = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isSearch
                  ? Icons.search_off_rounded
                  : Icons.event_available_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSearch
                ? 'لا توجد نتائج مطابقة للبحث'
                : 'لا توجد مواعيد لهذا اليوم',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              isSearch
                  ? 'تأكد من كتابة الاسم أو رقم الهاتف بدقة، أو امسح البحث لإظهار جميع المواعيد.'
                  : 'ابدأ بإضافة موعد جديد لجدول اليوم، أو اختر تاريخاً آخر من التقويم.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: AppColors.textSecondary(context),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSearch)
                OutlinedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: Text(
                    'مسح البحث',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, fontSize: 11.5),
                  ),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () {
                    AppNavigation.showBookAppointment(
                      context,
                      clinicId: widget.user.clinicId,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'حجز موعد الآن',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                  ),
                ),
                if (!isToday) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _goToToday,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                    ),
                    child: Text(
                      'العودة إلى اليوم',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── مساحة عمل طابور المراحل (Kanban View) ───
  Widget _buildKanbanWorkspace(
    List<AppointmentModel> allAppointments,
    AppointmentModel? activeSelected,
  ) {
    final filtered = allAppointments.where(_matchesFilter).toList();
    return AppointmentsKanbanView(
      user: widget.user,
      appointments: filtered,
      activeSelected: activeSelected,
      onSelectAppointment: (AppointmentModel appt) {
        setState(() {
          if (_selected?.id == appt.id) {
            _selected = null;
          } else {
            _selected = appt;
          }
        });
      },
      onCloseDetails: () => setState(() => _selected = null),
    );
  }

  // ─── زر تبديل نمط العرض ───
  Widget _buildViewTab({
    required _ViewMode mode,
    required IconData icon,
    required String label,
  }) {
    final active = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color:
                  active ? AppColors.primary : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── فلاتر الطبيب والفرع ───
  Widget _buildDoctorFilterChip(BuildContext context) {
    final doctorsAsync =
        ref.watch(clinicDoctorsProvider(widget.user.clinicId));
    final selectedDoctorId = ref.watch(selectedDoctorFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return doctorsAsync.when(
      data: (doctors) {
        if (doctors.length <= 1) return const SizedBox.shrink();
        final canSeeAll = widget.user.isOwner ||
            widget.user.canViewReports ||
            widget.user.role == UserRole.secretary;
        if (!canSeeAll) return const SizedBox.shrink();

        final selectedDoctor =
            doctors.where((d) => d.id == selectedDoctorId).firstOrNull;
        final label = selectedDoctor != null
            ? DoctorUtils.formatTitle(selectedDoctor.fullName)
            : 'جميع الأطباء';
        final isFiltered = selectedDoctorId != null;

        return InkWell(
          onTap: () =>
              _showDoctorFilterSheet(context, doctors, selectedDoctorId),
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isFiltered
                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : AppColors.subtle(context),
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(
                color: isFiltered
                    ? AppColors.primary
                    : AppColors.borderSubtle(context),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 12,
                  color: isFiltered
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight:
                          isFiltered ? FontWeight.w700 : FontWeight.w600,
                      color: isFiltered
                          ? AppColors.primary
                          : AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isFiltered
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBranchFilterChip(BuildContext context) {
    final branchesAsync =
        ref.watch(clinicBranchesProvider(widget.user.clinicId));
    final selectedBranchId = ref.watch(selectedBranchFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return branchesAsync.when(
      data: (branches) {
        if (branches.length <= 1) return const SizedBox.shrink();

        final selectedBranch =
            branches.where((b) => b.id == selectedBranchId).firstOrNull;
        final label =
            selectedBranch != null ? selectedBranch.name : 'جميع الفروع';
        final isFiltered = selectedBranchId != null;

        return InkWell(
          onTap: () =>
              _showBranchFilterSheet(context, branches, selectedBranchId),
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isFiltered
                  ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                  : AppColors.subtle(context),
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(
                color: isFiltered
                    ? AppColors.primary
                    : AppColors.borderSubtle(context),
                width: isFiltered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 12,
                  color: isFiltered
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight:
                          isFiltered ? FontWeight.w700 : FontWeight.w600,
                      color: isFiltered
                          ? AppColors.primary
                          : AppColors.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isFiltered
                      ? AppColors.primary
                      : AppColors.textSecondary(context),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showDoctorFilterSheet(
    BuildContext context,
    List<UserModel> doctors,
    String? selectedDoctorId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'تصفية المواعيد حسب الطبيب',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildModalFilterPill(
                    context: context,
                    isSelected: selectedDoctorId == null,
                    label: 'جميع الأطباء',
                    onTap: () {
                      ref
                          .read(selectedDoctorFilterProvider.notifier)
                          .state = null;
                      Navigator.pop(ctx);
                    },
                  ),
                  ...doctors.map((doc) => _buildModalFilterPill(
                        context: context,
                        isSelected: doc.id == selectedDoctorId,
                        label: DoctorUtils.formatTitle(doc.fullName),
                        onTap: () {
                          ref
                              .read(selectedDoctorFilterProvider.notifier)
                              .state = doc.id;
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchFilterSheet(
    BuildContext context,
    List<BranchModel> branches,
    String? selectedBranchId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadii.md)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'تصفية المواعيد حسب الفرع',
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildModalFilterPill(
                    context: context,
                    isSelected: selectedBranchId == null,
                    label: 'جميع الفروع',
                    onTap: () {
                      ref
                          .read(selectedBranchFilterProvider.notifier)
                          .state = null;
                      Navigator.pop(ctx);
                    },
                  ),
                  ...branches.map((br) => _buildModalFilterPill(
                        context: context,
                        isSelected: br.id == selectedBranchId,
                        label: br.name,
                        onTap: () {
                          ref
                              .read(selectedBranchFilterProvider.notifier)
                              .state = br.id;
                          Navigator.pop(ctx);
                        },
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalFilterPill({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primarySubtle : AppColors.subtle(context),
          borderRadius: BorderRadius.circular(AppRadii.xs),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderSubtle(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color:
                isSelected ? AppColors.primary : AppColors.textPrimary(context),
          ),
        ),
      ),
    );
  }
}

/// بطاقة Bento KPI إحصائية تفاعلية مدمجة للمواعيد.
class _BentoAppointmentKpiTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color bgTint;
  final bool isSelected;
  final double? progress;
  final VoidCallback onTap;

  const _BentoAppointmentKpiTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bgTint,
    required this.isSelected,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.borderSubtle(context),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.20 : 0.10)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? accentColor
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: bgTint,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 13.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? accentColor : AppColors.textPrimary(context),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted(context),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: AppColors.subtle(context),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
