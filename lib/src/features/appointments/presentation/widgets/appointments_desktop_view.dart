import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/appointment_model.dart';
import 'desktop/calendar_pane.dart';
import 'desktop/details_pane.dart';
import 'desktop/list_pane.dart';

/// Desktop appointments view — 3-pane layout:
///   left (240px): calendar
///   center (flex 3): appointment list for selected day
///   right (flex 4): selected appointment details
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 240,
            child: Card(
              child: const DesktopCalendarPane(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Card(
              child: DesktopListPane(
                user: widget.user,
                selected: _selected,
                onSelect: (AppointmentModel a) => setState(() => _selected = a),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Card(
              child: DesktopDetailsPane(
                user: widget.user,
                selected: _selected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}