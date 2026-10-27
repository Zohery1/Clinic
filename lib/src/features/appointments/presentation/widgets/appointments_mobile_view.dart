import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/data/app_stat_card.dart';
import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_error_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/primitives/app_chip.dart';
import '../../../../core/ui/primitives/app_input.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/domain/user_model.dart';
import '../../../reports/presentation/reports_controller.dart';
import '../../domain/appointment_model.dart';
import '../appointments_controller.dart';
import '../book_appointment_dialog.dart';
import 'appointment_card.dart';
import 'appointments_calendar_strip.dart';

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
  ConsumerState<AppointmentsMobileView> createState() =>
      _AppointmentsMobileViewState();
}

enum _AppointmentFilter { all, waiting, withDoctor, completed, cancelled }

extension on _AppointmentFilter {
  String get label {
    switch (this) {
      case _AppointmentFilter.all:
        return 'الكل';
      case _AppointmentFilter.waiting:
        return 'في الانتظار';
      case _AppointmentFilter.withDoctor:
        return 'مع الطبيب';
      case _AppointmentFilter.completed:
        return 'منتهي';
      case _AppointmentFilter.cancelled:
        return 'ملغي';
    }
  }

  bool matches(AppointmentModel a) {
    final s = a.status.toLowerCase();
    switch (this) {
      case _AppointmentFilter.all:
        return true;
      case _AppointmentFilter.waiting:
        return s == 'confirmed';
      case _AppointmentFilter.withDoctor:
        return s == 'pending';
      case _AppointmentFilter.completed:
        return s == 'completed';
      case _AppointmentFilter.cancelled:
        return s.startsWith('cancelled');
    }
  }
}

class _FilterSpec {
  final _AppointmentFilter filter;
  final Color color;
  const _FilterSpec(this.filter, this.color);
}

class _AppointmentsMobileViewState
    extends ConsumerState<AppointmentsMobileView> {
  _AppointmentFilter _filter = _AppointmentFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const _filterSpecs = <_FilterSpec>[
    _FilterSpec(_AppointmentFilter.all, AppColors.primary),
    _FilterSpec(_AppointmentFilter.waiting, AppColors.warning),
    _FilterSpec(_AppointmentFilter.withDoctor, AppColors.info),
    _FilterSpec(_AppointmentFilter.completed, AppColors.success),
    _FilterSpec(_AppointmentFilter.cancelled, AppColors.danger),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() => _searchQuery = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBooking,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'حجز جديد',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(todayAppointmentsProvider);
          ref.invalidate(todayRevenueProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          children: [
            AppointmentsCalendarStrip(
              selectedDate: widget.selectedDate,
              user: widget.user,
            ),
            const SizedBox(height: AppSpace.md),
            _RevenueSummary(appointmentsAsync: widget.appointmentsAsync),
            const SizedBox(height: AppSpace.md),
            _SearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            const SizedBox(height: AppSpace.md),
            _FilterRow(
              appointmentsAsync: widget.appointmentsAsync,
              selected: _filter,
              specs: _filterSpecs,
              onSelect: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: AppSpace.lg),
            _List(
              appointmentsAsync: widget.appointmentsAsync,
              filter: _filter,
              searchQuery: _searchQuery,
              clinicId: widget.user.clinicId,
            ),
            const SizedBox(height: AppSpace.huge),
          ],
        ),
      ),
    );
  }

  void _openBooking() {
    showDialog<void>(
      context: context,
      builder: (_) => BookAppointmentDialog(clinicId: widget.user.clinicId),
    );
  }
}

class _RevenueSummary extends ConsumerWidget {
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  const _RevenueSummary({required this.appointmentsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final count = appointmentsAsync.value?.length;
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            title: 'إيرادات اليوم',
            value: todayRevenueAsync.when(
              data: (v) => v.toStringAsFixed(0),
              loading: () => '—',
              error: (_, __) => '—',
            ),
            subtitle: 'جنيه مصري',
            icon: Icons.payments_outlined,
            color: AppColors.success,
            isLoading: todayRevenueAsync.isLoading,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: AppStatCard(
            title: 'مواعيد اليوم',
            value: count?.toString() ?? '—',
            subtitle: 'حجز نشط',
            icon: Icons.people_alt_outlined,
            color: AppColors.primary,
            isLoading: appointmentsAsync.isLoading,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: 'بحث بالاسم أو الهاتف...',
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      suffixIcon: query.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              tooltip: 'مسح البحث',
            )
          : null,
      onChanged: onChanged,
    );
  }
}

class _FilterRow extends StatelessWidget {
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  final _AppointmentFilter selected;
  final List<_FilterSpec> specs;
  final ValueChanged<_AppointmentFilter> onSelect;

  const _FilterRow({
    required this.appointmentsAsync,
    required this.selected,
    required this.specs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return appointmentsAsync.maybeWhen(
      data: (list) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < specs.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.sm),
                _CountedFilterChip(
                  spec: specs[i],
                  count: list.where(specs[i].filter.matches).length,
                  isSelected: selected == specs[i].filter,
                  onTap: () => onSelect(specs[i].filter),
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox(height: 32),
    );
  }
}

class _CountedFilterChip extends StatelessWidget {
  final _FilterSpec spec;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountedFilterChip({
    required this.spec,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: '${spec.filter.label}  $count',
      variant: AppChipVariant.filter,
      selected: isSelected,
      color: spec.color,
      onSelected: (_) => onTap(),
    );
  }
}

class _List extends ConsumerWidget {
  final AsyncValue<List<AppointmentModel>> appointmentsAsync;
  final _AppointmentFilter filter;
  final String searchQuery;
  final String clinicId;

  const _List({
    required this.appointmentsAsync,
    required this.filter,
    required this.searchQuery,
    required this.clinicId,
  });

  bool _matchesSearch(AppointmentModel a, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final patientName = a.patient.fullName.toLowerCase();
    final phone = (a.patient.phone ?? '').toLowerCase();
    final typeName = (a.appointmentTypeName ?? '').toLowerCase();
    return patientName.contains(q) || phone.contains(q) || typeName.contains(q);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return appointmentsAsync.when(
      data: (list) {
        final filtered = list
            .where((a) => filter.matches(a) && _matchesSearch(a, searchQuery))
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
        if (filtered.isEmpty) {
          return AppEmptyState(
            icon: Icons.event_busy_rounded,
            title: searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد مواعيد في هذا القسم',
            message: searchQuery.isNotEmpty
                ? 'جرب تغيير كلمات البحث أو المسح'
                : 'يمكنك إضافة موعد جديد بالضغط على زر حجز جديد',
          );
        }
        return Column(
          children: [
            for (int i = 0; i < filtered.length; i++) ...[
              _StaggeredEntry(
                index: i,
                child: AppointmentCard(
                  appointment: filtered[i],
                  clinicId: clinicId,
                ),
              ),
              if (i < filtered.length - 1)
                const SizedBox(height: AppSpace.md),
            ],
          ],
        );
      },
      loading: () => Column(
        children: List.generate(
          3,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpace.md),
            child: AppSkeleton(
              height: 120,
              radius: AppRadii.radiusMd,
            ),
          ),
        ),
      ),
      error: (err, _) => AppErrorState(
        title: 'تعذر تحميل المواعيد',
        message: err.toString(),
        onRetry: () => ref.invalidate(todayAppointmentsProvider),
      ),
    );
  }
}

class _StaggeredEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredEntry({required this.index, required this.child});

  @override
  State<_StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<_StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 240 + (widget.index.clamp(0, 10) * 35),
      ),
    );
    Future.delayed(
      Duration(milliseconds: widget.index.clamp(0, 10) * 35),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 12),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
