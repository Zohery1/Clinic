import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../../core/ui/tokens/colors.dart';
import '../../../../../../core/ui/tokens/spacing.dart';
import '../../../../../../core/ui/tokens/typography.dart';
import '../../../../../../core/utils/doctor_utils.dart';
import '../../../../domain/appointment_type_model.dart';
import '../../../../domain/service_model.dart';
import '../../appointment_time_picker.dart';

class StepSummary extends ConsumerWidget {
  final String clinicId;
  final String? patientId;
  final String? patientName;
  final String? doctorName;
  final String? branchName;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final AppointmentTypeModel? selectedType;
  final List<ServiceModel> selectedServices;

  const StepSummary({
    super.key,
    required this.clinicId,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.branchName,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedType,
    required this.selectedServices,
  });

  double get _basePrice => selectedType?.price ?? 0.0;
  double get _servicesTotal =>
      selectedServices.fold<double>(0.0, (sum, s) => sum + s.price);
  double get _total => _basePrice + _servicesTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة وتأكيد',
            style: AppTypography.headingLg(AppColors.textPrimary(context)),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'راجع بيانات الموعد قبل تأكيد الحجز',
            style: AppTypography.bodySm(AppColors.textSecondary(context)),
          ),
          const SizedBox(height: AppSpace.lg),
          _SummaryCard(
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.person_outline_rounded,
                  label: 'المريض',
                  value: patientName ?? '—',
                ),
                const _HDivider(),
                if (selectedType != null)
                  _SummaryRow(
                    icon: Icons.medical_information_outlined,
                    label: 'نوع الكشف',
                    value:
                        '${selectedType!.name} (${selectedType!.price.toStringAsFixed(0)} ج.م)',
                  ),
                if (selectedType != null) const _HDivider(),
                _SummaryRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'التاريخ',
                  value: intl.DateFormat('EEEE، d MMMM yyyy', 'ar')
                      .format(selectedDate),
                ),
                const _HDivider(),
                _SummaryRow(
                  icon: Icons.access_time_rounded,
                  label: 'الوقت',
                  value:
                      AppointmentTimePicker.formatArabicTime(selectedTime),
                ),
                if (doctorName != null) ...[
                  const _HDivider(),
                  _SummaryRow(
                    icon: Icons.person_pin_outlined,
                    label: 'الطبيب',
                    value: DoctorUtils.formatTitle(doctorName),
                  ),
                ],
                if (branchName != null) ...[
                  const _HDivider(),
                  _SummaryRow(
                    icon: Icons.storefront_outlined,
                    label: 'الفرع',
                    value: branchName!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _SummaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص التكلفة',
                  style: AppTypography.headingSm(
                      AppColors.textPrimary(context)),
                ),
                const SizedBox(height: AppSpace.sm),
                _CostRow(
                  label: 'الكشف الأساسي',
                  value: '${_basePrice.toStringAsFixed(0)} ج.م',
                ),
                if (_servicesTotal > 0) ...[
                  const SizedBox(height: 4),
                  _CostRow(
                    label: 'خدمات إضافية (${selectedServices.length})',
                    value: '${_servicesTotal.toStringAsFixed(0)} ج.م',
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Divider(height: 1),
                ),
                _CostRow(
                  label: 'الإجمالي',
                  value: '${_total.toStringAsFixed(0)} ج.م',
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Widget child;
  const _SummaryCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.radiusLg),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary(context)),
          const SizedBox(width: AppSpace.sm),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  AppTypography.bodySm(AppColors.textSecondary(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySm(AppColors.textPrimary(context))
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HDivider extends StatelessWidget {
  const _HDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Divider(height: 1, color: AppColors.borderSubtle(context)),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _CostRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  @override
  Widget build(BuildContext context) {
    final color = emphasize ? AppColors.primary : AppColors.textPrimary(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm(emphasize
                ? AppColors.textPrimary(context)
                : AppColors.textSecondary(context)),
          ),
        ),
        Text(
          value,
          style: emphasize
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                )
              : GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
        ),
      ],
    );
  }
}



