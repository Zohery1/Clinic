import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../../core/ui/feedback/app_error_state.dart';
import '../../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../../core/ui/primitives/app_input.dart';
import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../../../core/ui/tokens/typography.dart';
import '../../../../auth/domain/user_model.dart';
import '../../appointments_controller.dart';
import '../../../domain/appointment_model.dart';
import '../appointment_card.dart';

/// Center pane: list of appointments for the selected day.
class DesktopListPane extends ConsumerStatefulWidget {
  final UserModel user;
  final AppointmentModel? selected;
  final ValueChanged<AppointmentModel> onSelect;

  const DesktopListPane({
    super.key,
    required this.user,
    required this.selected,
    required this.onSelect,
  });

  @override
  ConsumerState<DesktopListPane> createState() => _DesktopListPaneState();
}

class _DesktopListPaneState extends ConsumerState<DesktopListPane> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';

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
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
    });
  }

  bool _matchesSearch(AppointmentModel appointment) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery;
    final patientName = appointment.patient.fullName.toLowerCase();
    final patientPhone = appointment.patient.phone?.toLowerCase() ?? '';
    final doctorName = appointment.doctorName?.toLowerCase() ?? '';
    final appointmentTypeName = appointment.appointmentTypeName?.toLowerCase() ?? '';

    return patientName.contains(query) ||
        patientPhone.contains(query) ||
        doctorName.contains(query) ||
        appointmentTypeName.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final async = ref.watch(todayAppointmentsProvider);
    final dateLabel =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مواعيد اليوم',
            style: AppTypography.headingLg(AppColors.textPrimary(context)),
          ),
          const SizedBox(height: 2),
          Text(
            dateLabel,
            style: AppTypography.bodySm(AppColors.textSecondary(context)),
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            controller: _searchController,
            hint: 'البحث بالاسم، الهاتف، الطبيب، نوع الكشف...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: _clearSearch,
                    tooltip: 'مسح البحث',
                  )
                : null,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: async.when(
              data: (list) {
                final sorted = [...list]
                  ..sort((a, b) =>
                      a.appointmentDate.compareTo(b.appointmentDate));
                final filtered = sorted.where(_matchesSearch).toList();

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: _searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.event_busy_rounded,
                    title: _searchQuery.isNotEmpty
                        ? 'لا توجد نتائج'
                        : 'لا توجد مواعيد',
                    message: _searchQuery.isNotEmpty
                        ? 'لم يتم العثور على مواعيد مطابقة لـ "$_searchQuery"'
                        : 'لم يتم تسجيل أي مواعيد لهذا اليوم بعد',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpace.md),
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    return AppointmentCard(
                      appointment: a,
                      clinicId: widget.user.clinicId,
                      queueIndex: i + 1,
                      isSelected: widget.selected?.id == a.id,
                      onTap: () => widget.onSelect(a),
                    );
                  },
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
              error: (e, _) => AppErrorState(
                title: 'تعذر التحميل',
                message: e.toString(),
                onRetry: () => ref.invalidate(todayAppointmentsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
