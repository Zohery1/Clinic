import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/patient_model.dart';
import '../widgets/add_patient_dialog.dart';
import '../widgets/edit_patient_dialog.dart';
import '../widgets/patient_medical_profile_view.dart';
import 'patients_delete_dialog.dart';
import 'patients_list_panel.dart';

class PatientsDesktopLayout extends ConsumerStatefulWidget {
  final String clinicId;
  final UserModel user;

  const PatientsDesktopLayout({
    super.key,
    required this.clinicId,
    required this.user,
  });

  @override
  ConsumerState<PatientsDesktopLayout> createState() =>
      _PatientsDesktopLayoutState();
}

class _PatientsDesktopLayoutState
    extends ConsumerState<PatientsDesktopLayout> {
  PatientModel? _selectedPatient;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPatient;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            border: BorderDirectional(end: BorderSide(
                color: AppColors.borderSubtle(context),
                width: 1,
              ),
            ),
          ),
          child: PatientsListPanel(
            clinicId: widget.clinicId,
            user: widget.user,
            selectedPatient: selected,
            showAddButton: true,
            onSelect: (p) => setState(() => _selectedPatient = p),
            onAdd: () => _openAddDialog(),
            onEdit: (p) => _openEditDialog(p),
            onDelete: (p) => _openDeleteDialog(p),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected == null
                ? const AppEmptyState(
                    key: ValueKey('empty'),
                    icon: Icons.assignment_ind_outlined,
                    title: 'يرجى اختيار مريض من القائمة',
                    message:
                        'لعرض وتعديل ملفه الطبي وسجل زياراته وتفاصيل الحالات.',
                  )
                : KeyedSubtree(
                    key: ValueKey(selected.id),
                    child: PatientMedicalProfileView(
                      clinicId: widget.clinicId,
                      user: widget.user,
                      patient: selected,
                      fileNumbers: const {},
                      onEdit: () => _openEditDialog(selected),
                      onDelete: () => _openDeleteDialog(selected),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddPatientDialog(clinicId: widget.clinicId),
    );
  }

  void _openEditDialog(PatientModel p) {
    showDialog(
      context: context,
      builder: (ctx) => EditPatientDialog(
        clinicId: widget.clinicId,
        patient: p,
      ),
    );
  }

  Future<void> _openDeleteDialog(PatientModel p) async {
    await showPatientsDeleteDialog(
      context: context,
      ref: ref,
      clinicId: widget.clinicId,
      patient: p,
      onAfterDelete: () {
        if (!mounted) return;
        setState(() => _selectedPatient = null);
      },
    );
  }
}