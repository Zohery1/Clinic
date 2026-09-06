import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../auth/domain/user_model.dart';
import '../../domain/patient_model.dart';
import '../../data/patient_repository.dart';
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
    final patientsAsync = ref.watch(patientsListProvider(widget.clinicId));
    final full = patientsAsync.value ?? <PatientModel>[];
    final sortedFull = List<PatientModel>.from(full)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final fileNumbers = <String, int>{};
    for (int i = 0; i < sortedFull.length; i++) {
      fileNumbers[sortedFull[i].id] = i + 1;
    }

    // Synchronize selected patient state:
    // If the selected patient was deleted, gracefully reset to null.
    // If updated, update the reference.
    final currentSelected = _selectedPatient;
    PatientModel? selected = currentSelected;
    if (currentSelected != null && patientsAsync.hasValue) {
      final selectedId = currentSelected.id;
      final matching = full.where((p) => p.id == selectedId).firstOrNull;
      if (matching == null) {
        selected = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedPatient != null) {
            setState(() => _selectedPatient = null);
          }
        });
      } else if (matching != _selectedPatient) {
        selected = matching;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedPatient != matching) {
            setState(() => _selectedPatient = matching);
          }
        });
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth < 1200 ? 300.0 : 350.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: panelWidth,
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                border: BorderDirectional(
                  end: BorderSide(
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
                          fileNumbers: fileNumbers,
                          onEdit: () => _openEditDialog(selected!),
                          onDelete: () => _openDeleteDialog(selected!),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
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