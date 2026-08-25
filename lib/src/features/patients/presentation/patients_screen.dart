import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_motion.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../data/patient_repository.dart';
import '../domain/patient_model.dart';
import '../../appointments/presentation/book_appointment_dialog.dart';
import 'patient_details_dialog.dart';
import '../../../core/widgets/send_whatsapp_dialog.dart';
import 'widgets/add_patient_dialog.dart';
import 'widgets/edit_patient_dialog.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../../core/widgets/doctor_badge.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/domain/appointment_model.dart';

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
            'هل أنت متأكد من حذف المريض "${_capitalizeName(patient.fullName)}"؟\nسيتم حذف جميع الحجوزات والسجلات التابعة له.',
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

  PatientModel? _selectedPatient;

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'مع الطبيب';
      case 'confirmed':
        return 'في الانتظار';
      case 'completed':
        return 'منتهي';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'في الانتظار';
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Theme.of(context).colorScheme.primary;
      case 'confirmed':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
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
                                    _HoverScaleButton(
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
                                : _buildDesktopPatientList(
                                    patientsList,
                                    user.clinicId,
                                    user,
                                    activePatient,
                                    fileNumbers,
                                  ),
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
                        : _buildSelectedPatientProfile(context, user.clinicId, user, activePatient, fileNumbers),
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
                      // شريط البحث
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
                            : _buildPatientsList(
                                patientsList,
                                user.clinicId,
                                user,
                                fileNumbers,
                              ),
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

  Widget _buildDesktopPatientList(List<PatientModel> patients, String clinicId, UserModel user, PatientModel? activePatient, Map<String, int> fileNumbers) {
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

        return _PatientListCard(
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

  Widget _buildSelectedPatientProfile(BuildContext context, String clinicId, UserModel user, PatientModel activePatient, Map<String, int> fileNumbers) {
    final patient = activePatient;
    final age = _calculateAge(patient.birthDate);
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patient.id));

    final fileNo = '#${fileNumbers[patient.id] ?? ""}';
    final displayAddress = patient.address ?? '';
    final medicalHistory = patient.medicalHistory ??
        ((patient.address != null && patient.address!.contains('|'))
            ? patient.address!.split('|').last.trim()
            : '');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header Info Card ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _PatientAvatar(
                  gender: patient.gender,
                  
                  radius: 30,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _capitalizeName(patient.fullName),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (age != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$age سنة',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (patient.phone != null && patient.phone!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                const SizedBox(width: 6),
                                Text(patient.phone!, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7))),
                              ],
                            ),
                          if (displayAddress.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                const SizedBox(width: 6),
                                Text(
                                  displayAddress,
                                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Actions buttons
                Row(
                  children: [
                    _HoverScaleButton(
                      tooltip: 'تعديل البيانات',
                      onTap: () => _showEditPatientDialog(context, clinicId, patient),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (user.role == UserRole.doctor) ...[
                      _HoverScaleButton(
                        tooltip: 'حذف المريض',
                        onTap: () => _showDeleteConfirmationDialog(context, clinicId, patient),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error, size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => BookAppointmentDialog(
                            clinicId: clinicId,
                            preselectedPatientId: patient.id,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_task_rounded, size: 16),
                      label: const Text('حجز موعد جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Vitals and clinical variables grid ───
          LayoutBuilder(
            builder: (context, profileConstraints) {
              final isWide = profileConstraints.maxWidth >= 700;
              final items = [
                _buildClinicalMetaItem(
                  'رقم الهاتف',
                  patient.phone != null && patient.phone!.isNotEmpty ? patient.phone! : 'غير مسجل',
                  Icons.phone_rounded,
                  Theme.of(context).colorScheme.primary,
                  onActionTap: (patient.phone != null && patient.phone!.isNotEmpty)
                      ? () => showSendWhatsAppDialog(context, ref, phone: patient.phone!, patientName: patient.fullName)
                      : null,
                  actionTooltip: 'إرسال رسالة واتساب للمريض',
                ),
                _buildClinicalMetaItem('العنوان', displayAddress.isNotEmpty ? displayAddress : 'غير مسجل', Icons.location_on_outlined, AppTheme.success),
                _buildClinicalMetaItem('العمر', age != null ? '$age سنة' : 'غير مسجل', Icons.cake_outlined, AppTheme.warning),
                _buildClinicalMetaItem('رقم الملف', fileNo, Icons.badge_rounded, AppTheme.completed),
              ];

              if (isWide) {
                return Row(
                  children: [
                    items[0],
                    const SizedBox(width: 12),
                    items[1],
                    const SizedBox(width: 12),
                    items[2],
                    const SizedBox(width: 12),
                    items[3],
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        items[0],
                        const SizedBox(width: 12),
                        items[1],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        items[2],
                        const SizedBox(width: 12),
                        items[3],
                      ],
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // ─── Medical History Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, color: Theme.of(context).colorScheme.error, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'السجل المرضي للمريض',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  medicalHistory.isNotEmpty ? medicalHistory : 'لا يوجد سجل مرضي مسجل.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'سجل الزيارات والتشخيص',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.titleMedium?.color),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 8),
          const SizedBox(height: 12),

          // Appointments timeline
          Expanded(
            child: _buildAppointmentsTimeline(appointmentsAsync, clinicId, patient, user),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalMetaItem(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool useExpanded = true,
    VoidCallback? onActionTap,
    IconData? actionIcon,
    Color? actionColor,
    String? actionTooltip,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: actionTooltip ?? '',
                        child: InkWell(
                          onTap: onActionTap,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (actionColor ?? AppTheme.success).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              actionIcon ?? Icons.chat_bubble_outline_rounded,
                              color: actionColor ?? AppTheme.success,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (useExpanded) {
      return Expanded(child: content);
    }
    return content;
  }

  Widget _buildAppointmentsTimeline(AsyncValue<List<AppointmentModel>> appointmentsAsync, String clinicId, PatientModel patient, UserModel user) {
    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Center(
            child: EmptyStateView(
              icon: Icons.history_rounded,
              title: 'لا توجد زيارات سابقة مسجلة للمريض',
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: appointments.length,
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            final app = appointments[index];
            final date = intl.DateFormat('yyyy/MM/dd', 'ar').format(app.appointmentDate.toLocal());
            final time = intl.DateFormat('hh:mm a', 'ar').format(app.appointmentDate.toLocal());
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Stack(
              children: [
                if (index != appointments.length - 1)
                  Positioned(
                    top: 16,
                    bottom: 0,
                    right: 5,
                    child: Container(
                      width: 2,
                      color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 28, bottom: 20),
                  child: _TimelineAppointmentCard(
                    app: app,
                    date: date,
                    time: time,
                    clinicId: clinicId,
                    patient: patient,
                    user: user,
                    getStatusColor: _getStatusColor,
                    translateStatus: _translateStatus,
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (err, _) => ErrorStateView(
        message: 'خطأ: $err',
        onRetry: () => ref.invalidate(patientAppointmentsProvider(patient.id)),
      ),
    );
  }

  Widget _buildPatientsList(List<PatientModel> patients, String clinicId, UserModel user, Map<String, int> fileNumbers) {
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
        

        return _PatientListCard(
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

class _PatientListCard extends StatefulWidget {
  final PatientModel patient;
  final int fileNo;
  final bool isSelected;
  final Color? doctorColor;
  final VoidCallback onTap;
  final VoidCallback onBookAppointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  const _PatientListCard({
    required this.patient,
    required this.fileNo,
    required this.isSelected,
    this.doctorColor,
    required this.onTap,
    required this.onBookAppointment,
    required this.onEdit,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  State<_PatientListCard> createState() => _PatientListCardState();
}

class _PatientListCardState extends State<_PatientListCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHovered = _isHovered;
    final showHoverEffect = isHovered && !isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        margin: const EdgeInsets.only(bottom: 8),
        transform: showHoverEffect ? (Matrix4.identity()..scale(1.015)) : Matrix4.identity(),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
              )
            : AppTheme.cardDecoration(context).copyWith(
                boxShadow: showHoverEffect
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : AppTheme.cardDecoration(context).boxShadow,
              ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _PatientAvatar(
                  gender: widget.patient.gender,
                  doctorColor: widget.doctorColor,
                  radius: 22,
                  showFileNumber: true,
                  fileNo: widget.fileNo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _capitalizeName(widget.patient.fullName),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.patient.phone != null && widget.patient.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.patient.phone!,
                          style: GoogleFonts.jetBrainsMono(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HoverScaleButton(
                      tooltip: 'حجز موعد جديد',
                      onTap: widget.onBookAppointment,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_task_rounded, color: AppTheme.primary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'خيارات أخرى',
                      icon: Icon(Icons.more_vert_rounded, color: AppTheme.textHint, size: 18),
                      onSelected: (action) {
                        if (action == 'edit') {
                          widget.onEdit();
                        } else if (action == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: AppTheme.primary, size: 16),
                              SizedBox(width: 8),
                              Text('تعديل البيانات', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        if (widget.canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 16),
                                SizedBox(width: 8),
                                Text('حذف المريض', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _PatientAvatar extends StatelessWidget {
  final String? gender;
  final Color? doctorColor;
  final double radius;
  final bool showFileNumber;
  final int fileNo;

  const _PatientAvatar({
    this.gender,
    this.doctorColor,
    required this.radius,
    this.showFileNumber = false,
    this.fileNo = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasDoctor = doctorColor != null;
    final avatarColor = gender == 'female'
        ? AppTheme.doctorPalette[4]
        : Theme.of(context).colorScheme.primary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasDoctor
                ? LinearGradient(
                    colors: [
                      doctorColor!.withValues(alpha: 0.3),
                      doctorColor!.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      avatarColor.withValues(alpha: 0.3),
                      avatarColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: hasDoctor
                ? Border.all(color: doctorColor!, width: 2)
                : Border.all(color: avatarColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Center(
            child: Icon(
              gender == 'female' ? Icons.woman_rounded : Icons.man_rounded,
              color: hasDoctor ? doctorColor : avatarColor,
              size: radius * 0.75,
            ),
          ),
        ),
        if (showFileNumber)
          Positioned(
            bottom: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '#$fileNo',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HoverScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final String? tooltip;
  final Widget child;

  const _HoverScaleButton({
    required this.onTap,
    this.tooltip,
    required this.child,
  });

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovered ? 1.1 : 1.0),
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TimelineAppointmentCard extends ConsumerStatefulWidget {
  final AppointmentModel app;
  final String date;
  final String time;
  final String clinicId;
  final PatientModel patient;
  final UserModel user;
  final Color Function(BuildContext, String) getStatusColor;
  final String Function(String) translateStatus;

  const _TimelineAppointmentCard({
    required this.app,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.patient,
    required this.user,
    required this.getStatusColor,
    required this.translateStatus,
  });

  @override
  ConsumerState<_TimelineAppointmentCard> createState() => _TimelineAppointmentCardState();
}

class _TimelineAppointmentCardState extends ConsumerState<_TimelineAppointmentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(widget.date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Theme.of(context).textTheme.bodyLarge?.color)),
                      const SizedBox(width: 8),
                      Text(widget.time, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DoctorBadge(
                          doctorId: widget.app.doctorId,
                          doctorName: widget.app.doctorName,
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        StatusPill(
                          label: widget.translateStatus(widget.app.status),
                          color: widget.getStatusColor(context, widget.app.status),
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1),
                      AppointmentServicesSection(appointmentId: widget.app.id),
                      PatientVisitNoteSection(
                        clinicId: widget.clinicId,
                        appointmentId: widget.app.id,
                        patientId: widget.patient.id,
                        patientName: widget.patient.fullName,
                        isDoctor: widget.user.role == UserRole.doctor,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}