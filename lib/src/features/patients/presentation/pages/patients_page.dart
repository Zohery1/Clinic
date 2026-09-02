import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../auth/presentation/login_controller.dart';
import 'patients_desktop_layout.dart';
import 'patients_mobile_layout.dart';

/// Content-only widget for the Patients tab. The parent [AppShell]
/// (hosted by [DashboardScreen]) provides the sidebar, top bar, and
/// navigation. This screen renders only the inner patient layouts.
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
    final isDesktop = width >= 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: isDesktop
            ? PatientsDesktopLayout(clinicId: user.clinicId, user: user)
            : PatientsMobileLayout(clinicId: user.clinicId, user: user),
      ),
    );
  }
}