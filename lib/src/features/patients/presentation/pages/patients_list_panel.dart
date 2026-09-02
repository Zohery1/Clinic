import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/feedback/app_empty_state.dart';
import '../../../../core/ui/feedback/app_skeleton.dart';
import '../../../../core/ui/primitives/app_button.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../appointments/presentation/book_appointment_dialog.dart';
import '../../../auth/domain/user_model.dart';
import '../../data/patient_repository.dart';
import '../../domain/patient_model.dart';
import '../widgets/patient_list_card.dart';
import 'patients_search_header.dart';

typedef PatientsListData = ({
  List<PatientModel> patients,
  Map<String, int> fileNumbers,
  bool isLoading,
});

class PatientsListPanel extends ConsumerStatefulWidget {
  final String clinicId;
  final UserModel user;
  final PatientModel? selectedPatient;
  final ValueChanged<PatientModel> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<PatientModel> onEdit;
  final ValueChanged<PatientModel> onDelete;
  final bool showAddButton;
  final bool compactHeader;

  const PatientsListPanel({
    super.key,
    required this.clinicId,
    required this.user,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.selectedPatient,
    this.showAddButton = true,
    this.compactHeader = false,
  });

  @override
  ConsumerState<PatientsListPanel> createState() => _PatientsListPanelState();
}

class _PatientsListPanelState extends ConsumerState<PatientsListPanel> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool _isSearching = false;
  bool _searchByFileOnly = false;
  List<PatientModel>? _searchResults;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        final cached =
            ref.read(patientsListProvider(widget.clinicId)).value;
        final allPatients = cached ??
            await ref
                .read(patientRepositoryProvider)
                .getPatients(widget.clinicId);

        final sortedFull = List<PatientModel>.from(allPatients)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final fileNumbers = <String, int>{};
        for (int i = 0; i < sortedFull.length; i++) {
          fileNumbers[sortedFull[i].id] = i + 1;
        }
        final clean = query.trim();

        if (_searchByFileOnly) {
          final filtered = sortedFull.where((p) {
            final n = fileNumbers[p.id] ?? 0;
            return n.toString() == clean || n.toString().contains(clean);
          }).toList();
          if (mounted) {
            setState(() {
              _searchResults = filtered;
              _isSearching = false;
            });
          }
          return;
        }

        final results = ref
            .read(patientRepositoryProvider)
            .searchPatients(sortedFull, query);
        final byFile = sortedFull.where((p) {
          final n = fileNumbers[p.id] ?? 0;
          return n.toString() == clean || n.toString().contains(clean);
        }).toList();

        final merged = [...results];
        for (final p in byFile) {
          if (!merged.any((existing) => existing.id == p.id)) {
            merged.add(p);
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = merged;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _runSearch('');
  }

  void _toggleFileOnly(bool v) {
    setState(() => _searchByFileOnly = v);
    _runSearch(_searchController.text);
  }

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

    final raw = _searchResults ?? patientsAsync.value ?? <PatientModel>[];
    final list = List<PatientModel>.from(raw)
      ..sort((a, b) {
        final na = fileNumbers[a.id] ?? 0;
        final nb = fileNumbers[b.id] ?? 0;
        return na.compareTo(nb);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showAddButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: AppButton(
                    label: '+ مريض جديد',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: widget.onAdd,
                    expand: false,
                  ),
                ),
              PatientsSearchHeader(
                controller: _searchController,
                focusNode: _searchFocusNode,
                searchByFileOnly: _searchByFileOnly,
                onToggleFileOnly: _toggleFileOnly,
                onChanged: _runSearch,
                onClear: _onClearSearch,
                compact: widget.compactHeader,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: AppColors.borderSubtle(context),
        ),
        Expanded(
          child: _isSearching || patientsAsync.isLoading
              ? const _LoadingList()
              : _buildList(list, fileNumbers),
        ),
      ],
    );
  }

  Widget _buildList(
    List<PatientModel> list,
    Map<String, int> fileNumbers,
  ) {
    if (list.isEmpty) {
      return const AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'لا توجد سجلات',
        message: 'ابدأ بإضافة أول مريض للعيادة.',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      padding: const EdgeInsets.all(AppSpace.md),
      itemBuilder: (context, index) {
        final p = list[index];
        final isSelected = widget.selectedPatient?.id == p.id;
        return PatientListCard(
          patient: p,
          fileNo: fileNumbers[p.id] ?? 0,
          isSelected: isSelected,
          onTap: () => widget.onSelect(p),
          onBookAppointment: () {
            showDialog(
              context: context,
              builder: (ctx) => BookAppointmentDialog(
                clinicId: widget.clinicId,
                preselectedPatientId: p.id,
              ),
            );
          },
          onEdit: () => widget.onEdit(p),
          onDelete: () => widget.onDelete(p),
          canDelete: widget.user.role == UserRole.doctor,
        );
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.md),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: Row(
            children: [
              const AppSkeletonCircle(size: 44),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    AppSkeletonText(width: 160, fontSize: 14),
                    SizedBox(height: 6),
                    AppSkeletonText(width: 110, fontSize: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}