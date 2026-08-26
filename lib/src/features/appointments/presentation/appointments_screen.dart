import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../domain/appointment_model.dart';
import 'appointments_controller.dart';
import '../data/appointment_repository.dart';
import '../../reports/presentation/reports_controller.dart';
import 'book_appointment_dialog.dart';
import 'widgets/queue_board.dart';
import 'widgets/queue_card.dart';
import '../../dashboard/presentation/notifications_controller.dart';
import '../../auth/presentation/subscription_status_sheet.dart';
import '../../clinics/presentation/widgets/clinic_switcher_button.dart';
import '../../clinics/presentation/clinics_controller.dart';

/// شاشة المواعيد — مطابقة لتصميم Stitch
/// شريط أيام أفقي + بطاقات مواعيد بتأثير waterfall
part 'appointments_screen_parts.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  final DateTime? subscriptionEndDate;
  final String? inviteCode;
  final String? clinicName;
  final String? clinicId;

  const AppointmentsScreen({
    super.key,
    this.subscriptionEndDate,
    this.inviteCode,
    this.clinicName,
    this.clinicId,
  });

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  int _selectedMobileTab = 0;

  void setSelectedMobileTab(int index) {
    setState(() => _selectedMobileTab = index);
  }

  String _getShortDayName(String label) {
    if (label.startsWith('ال')) {
      return label.substring(2);
    }
    return label;
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
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
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

  // ═══════════════════════════════════════════════
  // ─── Desktop Layout (2/3 area inside dashboard) ───
  // ═══════════════════════════════════════════════

  // ═══════════════════════════════════════════════
  // ─── Calendar Strip — Stitch: 7 أيام + أيقونة تقويم ───
  // ═══════════════════════════════════════════════

}