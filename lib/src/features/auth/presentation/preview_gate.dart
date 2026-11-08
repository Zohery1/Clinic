import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/demo/demo_clinical_data.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'login_controller.dart';

/// بوابة المعاينة السريرية المتقدمة (Instant Clinical Preview Gate)
class PreviewGate extends ConsumerStatefulWidget {
  const PreviewGate({super.key});

  @override
  ConsumerState<PreviewGate> createState() => _PreviewGateState();
}

class _PreviewGateState extends ConsumerState<PreviewGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentUserProvider.notifier).state = DemoClinicalData.doctorUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      clinicName: 'مستشفى وعيادات الأمل التخصصية',
      clinicId: 'demo-clinic-01',
      inviteCode: 'AMAL-2026',
      subscriptionEndDate: DateTime.now().add(const Duration(days: 365)),
    );
  }
}
