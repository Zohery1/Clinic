import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/patient_model.dart';
import '../patient_details_dialog.dart';
import '../widgets/add_patient_dialog.dart';
import '../widgets/edit_patient_dialog.dart';
import 'patients_delete_dialog.dart';
import 'patients_list_panel.dart';

class PatientsMobileLayout extends ConsumerWidget {
  final String clinicId;
  final UserModel user;

  const PatientsMobileLayout({
    super.key,
    required this.clinicId,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.lg,
            AppSpace.sm,
          ),
          child: AppButton(
            label: '+ مريض جديد',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => _openAddDialog(context),
          ),
        ),
        Expanded(
          child: PatientsListPanel(
            clinicId: clinicId,
            user: user,
            showAddButton: false,
            compactHeader: true,
            onSelect: (p) => _openDetails(context, p),
            onAdd: () => _openAddDialog(context),
            onEdit: (p) => _openEditDialog(context, p),
            onDelete: (p) => showPatientsDeleteDialog(
  context: context,
  ref: ref,
  clinicId: clinicId,
  patient: p,
  onAfterDelete: null,
            ),
          ),
        ),
      ],
    );
  }

  void _openAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AddPatientDialog(clinicId: clinicId),
    );
  }

  void _openEditDialog(BuildContext context, PatientModel p) {
    showDialog(
      context: context,
      builder: (ctx) => EditPatientDialog(clinicId: clinicId, patient: p),
    );
  }

  void _openDetails(BuildContext context, PatientModel p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientDetailsDialog(clinicId: clinicId, patient: p),
        fullscreenDialog: true,
      ),
    );
  }
}