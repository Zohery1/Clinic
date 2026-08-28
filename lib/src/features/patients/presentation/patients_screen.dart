import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../appointments/presentation/book_appointment_dialog.dart';
import '../data/patient_repository.dart';
import '../domain/patient_model.dart';
import 'patient_details_dialog.dart';
import 'widgets/add_patient_dialog.dart';
import 'widgets/edit_patient_dialog.dart';
import 'widgets/patient_list_card.dart';
import 'widgets/patient_medical_profile_view.dart';
import 'widgets/hover_scale_button.dart';

/// شاشة إدارة وسجلات المرضى (متوافقة بالكامل مع الويب، التابلت، والهواتف)
class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<PatientModel>? _searchResults;
  bool _isSearching = false;
  bool _searchByFileOnly = false;
  Timer? _debounceTimer;
  PatientModel? _selectedPatient;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, String clinicId) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final cached = ref.read(patientsListProvider(clinicId)).value;
        final allPatients =
            cached ?? await ref.read(patientRepositoryProvider).getPatients(clinicId);

        final sortedFullPatients = List<PatientModel>.from(allPatients)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final fileNumbers = <String, int>{};
        for (int i = 0; i < sortedFullPatients.length; i++) {
          fileNumbers[sortedFullPatients[i].id] = i + 1;
        }
        final cleanQuery = query.trim();

        if (_searchByFileOnly) {
          final filtered = sortedFullPatients.where((p) {
            final fileNo = fileNumbers[p.id] ?? 0;
            return fileNo.toString() == cleanQuery || fileNo.toString().contains(cleanQuery);
          }).toList();
          if (mounted) {
            setState(() {
              _searchResults = filtered;
              _isSearching = false;
            });
          }
        } else {
          final results = ref.read(patientRepositoryProvider).searchPatients(sortedFullPatients, query);
          final byFile = sortedFullPatients.where((p) {
            final fileNo = fileNumbers[p.id] ?? 0;
            return fileNo.toString() == cleanQuery || fileNo.toString().contains(cleanQuery);
          }).toList();

          final merged = [...results];
          for (var p in byFile) {
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
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  void _showAddPatientDialog(BuildContext context, String clinicId) {
    showDialog(
      context: context,
      builder: (context) => AddPatientDialog(clinicId: clinicId),
    );
  }

  void _showEditPatientDialog(BuildContext context, String clinicId, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => EditPatientDialog(clinicId: clinicId, patient: patient),
    ).then((value) {
      if (value == true && _searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text, clinicId);
      }
    });
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String clinicId, PatientModel patient) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'تأكيد الحذف',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف المريض "${PatientMedicalProfileView.capitalizeName(patient.fullName)}"؟\nسيتم حذف جميع الحجوزات والسجلات التابعة له.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                minimumSize: const Size(0, 42),
              ),
              onPressed: () async {
                try {
                  await ref.read(patientRepositoryProvider).deletePatient(patient.id);
                  ref.invalidate(patientsListProvider(clinicId));
                  if (_searchController.text.isNotEmpty) {
                    _onSearchChanged(_searchController.text, clinicId);
                  }
                  if (context.mounted) {
                    ClinicToast.showSuccess(context, 'تم حذف المريض بنجاح');
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ClinicToast.showError(context, 'خطأ: $e');
                  }
                }
              },
              child: const Text('نعم، احذف', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: Text('يرجى تسجيل الدخول أولاً')),
      );
    }

    final patientsAsync = ref.watch(patientsListProvider(user.clinicId));
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final fullPatients = patientsAsync.value ?? [];
    final sortedFullPatients = List<PatientModel>.from(fullPatients)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final Map<String, int> fileNumbers = {};
    for (int i = 0; i < sortedFullPatients.length; i++) {
      fileNumbers[sortedFullPatients[i].id] = i + 1;
    }

    final rawPatientsList = _searchResults ?? patientsAsync.value ?? [];
    final patientsList = List<PatientModel>.from(rawPatientsList)
      ..sort((a, b) {
        final noA = fileNumbers[a.id] ?? 0;
        final noB = fileNumbers[b.id] ?? 0;
        return noA.compareTo(noB);
      });
    final activePatient = _selectedPatient;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktopWidth = constraints.maxWidth >= 900;

            if (isDesktopWidth) {
              const listWidth = 360.0;
              final profileWidth = constraints.maxWidth - listWidth;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Right panel (Search + Patient List)
                  SizedBox(
                    width: listWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkBorder
                              : AppTheme.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        onChanged: (query) => _onSearchChanged(query, user.clinicId),
                                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                        decoration: InputDecoration(
                                          hintText: _searchByFileOnly ? 'ابحث برقم الملف...' : 'ابحث بالاسم، الهاتف...',
                                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
                                          suffixIcon: _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  tooltip: 'مسح البحث',
                                                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textHint, size: 20),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    _onSearchChanged('', user.clinicId);
                                                  },
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    HoverScaleButton(
                                      tooltip: 'مريض جديد',
                                      onTap: () => _showAddPatientDialog(context, user.clinicId),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _searchByFileOnly = !_searchByFileOnly;
                                              _onSearchChanged(_searchController.text, user.clinicId);
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: AnimatedContainer(
                                            duration: AppMotion.fast,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: _searchByFileOnly
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'بحث برقم الملف فقط',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _searchByFileOnly
                                                    ? Theme.of(context).colorScheme.onPrimary
                                                    : Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _isSearching
                                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                                : _buildDesktopList(patientsList, user.clinicId, user, activePatient, fileNumbers),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Left panel (Selected Patient's Medical Profile)
                  SizedBox(
                    width: profileWidth,
                    child: activePatient == null
                        ? const Center(
                            child: EmptyStateView(
                              icon: Icons.assignment_ind_outlined,
                              title: 'يرجى اختيار مريض من القائمة الجانبية',
                              subtitle: 'لعرض وتعديل ملفه الطبي وسجل زياراته وتفاصيل الحالات',
                            ),
                          )
                        : PatientMedicalProfileView(
                            clinicId: user.clinicId,
                            user: user,
                            patient: activePatient,
                            fileNumbers: fileNumbers,
                            onEdit: () => _showEditPatientDialog(context, user.clinicId, activePatient),
                            onDelete: () => _showDeleteConfirmationDialog(context, user.clinicId, activePatient),
                          ),
                  ),
                ],
              );
            } else {
              // Mobile view
              return Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (query) => _onSearchChanged(query, user.clinicId),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                hintText: _searchByFileOnly ? 'ابحث برقم الملف...' : 'ابحث بالاسم أو الهاتف...',
                                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHint),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'مسح البحث',
                                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textHint, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('', user.clinicId);
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _searchByFileOnly = !_searchByFileOnly;
                                  _onSearchChanged(_searchController.text, user.clinicId);
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _searchByFileOnly
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'رقم الملف',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _searchByFileOnly
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _isSearching
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                            : _buildMobileList(patientsList, user.clinicId, user, fileNumbers),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        floatingActionButton: isDesktop
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddPatientDialog(context, user.clinicId),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text('مريض جديد', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopList(
    List<PatientModel> patients,
    String clinicId,
    UserModel user,
    PatientModel? activePatient,
    Map<String, int> fileNumbers,
  ) {
    if (patients.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.people_outline_rounded,
          title: 'لا توجد سجلات مطابقة',
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: patients.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final patient = patients[index];
        final isSelected = activePatient?.id == patient.id;

        return PatientListCard(
          patient: patient,
          fileNo: fileNumbers[patient.id] ?? 0,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedPatient = patient;
            });
          },
          onBookAppointment: () {
            showDialog(
              context: context,
              builder: (context) => BookAppointmentDialog(
                clinicId: clinicId,
                preselectedPatientId: patient.id,
              ),
            );
          },
          onEdit: () => _showEditPatientDialog(context, clinicId, patient),
          onDelete: () => _showDeleteConfirmationDialog(context, clinicId, patient),
          canDelete: user.role == UserRole.doctor,
        );
      },
    );
  }

  Widget _buildMobileList(
    List<PatientModel> patients,
    String clinicId,
    UserModel user,
    Map<String, int> fileNumbers,
  ) {
    if (patients.isEmpty) {
      return const Center(
        child: EmptyStateView(
          icon: Icons.people_outline_rounded,
          title: 'لا توجد سجلات مطابقة',
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: patients.length,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final patient = patients[index];

        return PatientListCard(
          patient: patient,
          fileNo: fileNumbers[patient.id] ?? 0,
          isSelected: false,
          doctorColor: null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailsDialog(
                  clinicId: clinicId,
                  patient: patient,
                ),
              ),
            );
          },
          onBookAppointment: () {
            showDialog(
              context: context,
              builder: (context) => BookAppointmentDialog(
                clinicId: clinicId,
                preselectedPatientId: patient.id,
              ),
            );
          },
          onEdit: () => _showEditPatientDialog(context, clinicId, patient),
          onDelete: () => _showDeleteConfirmationDialog(context, clinicId, patient),
          canDelete: user.role == UserRole.doctor,
        );
      },
    );
  }
}