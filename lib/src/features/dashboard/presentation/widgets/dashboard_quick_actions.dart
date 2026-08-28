import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../patients/presentation/widgets/add_patient_dialog.dart';

/// شريط الإجراءات السريعة في لوحة التحكم
class DashboardQuickActions extends ConsumerWidget {
  final String? clinicId;
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardQuickActions({
    super.key,
    this.clinicId,
    this.onNavigateToTab,
  });

  void _openBookAppointment(BuildContext context, String effectiveClinicId) {
    showDialog(
      context: context,
      builder: (context) => BookAppointmentDialog(clinicId: effectiveClinicId),
    );
  }

  void _openAddPatient(BuildContext context, String effectiveClinicId) {
    showDialog(
      context: context,
      builder: (context) => AddPatientDialog(clinicId: effectiveClinicId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final effectiveClinicId = user?.clinicId ?? clinicId ?? '';
    final isOwner = user?.isOwner ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Action 1: New Appointment
          _buildActionButton(
            context: context,
            label: 'حجز جديد',
            icon: Icons.add_circle_outline_rounded,
            isPrimary: true,
            onTap: () => _openBookAppointment(context, effectiveClinicId),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action 2: Add Patient
          _buildActionButton(
            context: context,
            label: 'إضافة مريض',
            icon: Icons.person_add_alt_1_rounded,
            isPrimary: false,
            onTap: () => _openAddPatient(context, effectiveClinicId),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action 3: Appointments Tab
          _buildActionButton(
            context: context,
            label: 'جدول المواعيد',
            icon: Icons.calendar_month_rounded,
            isPrimary: false,
            onTap: () => onNavigateToTab?.call(1),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action 4: Patients Tab
          _buildActionButton(
            context: context,
            label: 'سجل المرضى',
            icon: Icons.people_alt_rounded,
            isPrimary: false,
            onTap: () => onNavigateToTab?.call(2),
          ),

          // Action 5: Reports Tab (if owner)
          if (isOwner) ...[
            const SizedBox(width: AppSpacing.sm),
            _buildActionButton(
              context: context,
              label: 'التقارير',
              icon: Icons.bar_chart_rounded,
              isPrimary: false,
              onTap: () => onNavigateToTab?.call(3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
