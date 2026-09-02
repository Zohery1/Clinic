import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/layout/app_shell.dart';
import '../../../../core/ui/layout/app_top_bar.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../auth/presentation/login_controller.dart';
import '../widgets/add_patient_dialog.dart';
import 'patients_desktop_layout.dart';
import 'patients_mobile_layout.dart';

/// Patients feature — responsive orchestrator. Splits between a
/// master-detail desktop layout (>=900px) and a single-column mobile
/// layout (<900px). Hosts the AppShell, breadcrumbs and primary action.
class PatientsPage extends ConsumerWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'يرجى تسجيل الدخول أولاً',
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppShell.kDesktopBreakpoint;

    return AppShell(
      currentRoute: '/patients',
      onNavigate: (_) {},
      user: user,
      title: 'المرضى',
      subtitle: 'سجل المرضى والمتابعة',
      breadcrumbs: const [
        AppBreadcrumbItem(label: 'الرئيسية'),
        AppBreadcrumbItem(label: 'المرضى'),
      ],
      actions: [
        AppButton(
          label: '+ مريض جديد',
          icon: Icons.person_add_alt_1_rounded,
          expand: false,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AddPatientDialog(clinicId: user.clinicId),
            );
          },
        ),
      ],
      child: isDesktop
          ? PatientsDesktopLayout(clinicId: user.clinicId, user: user)
          : PatientsMobileLayout(clinicId: user.clinicId, user: user),
    );
  }
}