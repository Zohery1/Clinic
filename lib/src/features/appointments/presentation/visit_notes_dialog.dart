import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../data/visit_note_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/service_model.dart';
import 'appointments_controller.dart';
import '../../reports/presentation/reports_controller.dart';

class VisitNotesDialog extends ConsumerStatefulWidget {
  final String clinicId;
  final String appointmentId;
  final String patientId;
  final String patientName;

  const VisitNotesDialog({
    super.key,
    required this.clinicId,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<VisitNotesDialog> createState() => _VisitNotesDialogState();
}

const _fieldSeparator = '\n---\n';

class _VisitNotesDialogState extends ConsumerState<VisitNotesDialog> {
  final _complaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _initialized = false;
  bool _servicesInitialized = false;
  List<ServiceModel> _selectedServices = [];

  @override
  void dispose() {
    _complaintController.dispose();
    _diagnosisController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _parseNotes(String rawNotes) {
    final parts = rawNotes.split(_fieldSeparator);
    _complaintController.text = parts.isNotEmpty ? parts[0].trim() : '';
    _diagnosisController.text = parts.length > 1 ? parts[1].trim() : '';
    _instructionsController.text = parts.length > 2 ? parts[2].trim() : '';
  }

  String _buildNotesText() {
    final complaint = _complaintController.text.trim();
    final diagnosis = _diagnosisController.text.trim();
    final instructions = _instructionsController.text.trim();

    final parts = [complaint, diagnosis, instructions];
    return parts.join(_fieldSeparator);
  }

  void _save(bool hasExisting) async {
    final text = _buildNotesText();
    final hasContent = _complaintController.text.trim().isNotEmpty ||
        _diagnosisController.text.trim().isNotEmpty ||
        _instructionsController.text.trim().isNotEmpty ||
        _selectedServices.isNotEmpty;

    if (!hasContent) {
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        SnackBar(duration: const Duration(seconds: 2), 
          content: const Text('يرجى كتابة التقرير الطبي أو اختيار خدمة واحدة على الأقل'),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFF59E0B)
              : const Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. حفظ التقرير الطبي إذا لم يكن فارغاً، أو حذفه إذا أفرغه الطبيب وكان موجوداً سابقاً
      if (text.replaceAll(_fieldSeparator, '').trim().isNotEmpty) {
        await ref.read(visitNoteRepositoryProvider).upsertVisitNote(
              clinicId: widget.clinicId,
              appointmentId: widget.appointmentId,
              patientId: widget.patientId,
              notes: text,
            );
      } else if (hasExisting) {
        await ref.read(visitNoteRepositoryProvider).deleteVisitNote(widget.appointmentId);
      }

      // 2. حفظ الخدمات المختارة للزيارة
      await ref.read(appointmentRepositoryProvider).updateAppointmentServices(
            clinicId: widget.clinicId,
            appointmentId: widget.appointmentId,
            selectedServices: _selectedServices,
          );

      // تحديث الموفرات (Providers)
      ref.invalidate(visitNoteProvider(widget.appointmentId));
      ref.invalidate(appointmentServicesProvider(widget.appointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
            content: Text(hasExisting ? 'تم تحديث التقرير والخدمات بنجاح' : 'تم حفظ التقرير والخدمات بنجاح'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF34D399)
                : const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _delete() async {
    setState(() => _isDeleting = true);

    try {
      // حذف التقرير والخدمات المرافقة
      await ref.read(visitNoteRepositoryProvider).deleteVisitNote(widget.appointmentId);
      await ref.read(appointmentRepositoryProvider).updateAppointmentServices(
            clinicId: widget.clinicId,
            appointmentId: widget.appointmentId,
            selectedServices: [],
          );

      ref.invalidate(visitNoteProvider(widget.appointmentId));
      ref.invalidate(appointmentServicesProvider(widget.appointmentId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayRevenueProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
            content: const Text('تم حذف التقرير والخدمات بنجاح'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(duration: const Duration(seconds: 2), 
            content: Text('حدث خطأ أثناء الحذف: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(visitNoteProvider(widget.appointmentId));
    final appServicesAsync = ref.watch(appointmentServicesProvider(widget.appointmentId));
    final availableServicesAsync = ref.watch(availableServicesProvider(widget.clinicId));
    final historyAsync = ref.watch(patientVisitNotesProvider(widget.patientId));
    
    final currentUser = ref.watch(currentUserProvider);
    final isDoctor = currentUser?.role == UserRole.doctor;

    final textPrimaryColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondaryColor = Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7) ?? Theme.of(context).hintColor;
    final borderLightColor = Theme.of(context).dividerColor;
    final badgeBgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 750;

    // تهيئة الخدمات المحددة مسبقاً بمجرد تحميلها
    availableServicesAsync.whenData((availableList) {
      appServicesAsync.whenData((appServicesList) {
        if (!_servicesInitialized) {
          _selectedServices = availableList.where((av) =>
            appServicesList.any((as) => as.serviceId == av.id)
          ).toList();
          _servicesInitialized = true;
        }
      });
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: noteAsync.when(
        data: (note) {
          if (!_initialized) {
            if (note != null) {
              _parseNotes(note.notes);
            }
            _initialized = true;
          }

          final hasExisting = note != null || _selectedServices.isNotEmpty;

          // ─── محتويات الجلسة الطبية الحالية ───
          final currentSessionChildren = [
            const SizedBox(height: 8),
            
            // 1. الشكوى المرضية والأعراض
            Row(
              children: [
                Icon(Icons.sick_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'الشكوى والأعراض المرضية:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _complaintController,
              maxLines: isMobile ? 3 : 3,
              minLines: 2,
              autofocus: isDoctor,
              readOnly: !isDoctor,
              style: TextStyle(color: textPrimaryColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isDoctor 
                    ? 'اكتب الشكوى المرضية والتاريخ المرضي هنا...'
                    : 'لا توجد شكوى مدونة.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // 2. التشخيص الطبي والنتائج
            Row(
              children: [
                Icon(Icons.biotech_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'التشخيص الطبي والنتائج:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _diagnosisController,
              maxLines: isMobile ? 3 : 3,
              minLines: 2,
              readOnly: !isDoctor,
              style: TextStyle(color: textPrimaryColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isDoctor 
                    ? 'اكتب التشخيص الطبي ونتائج الفحص والتحاليل...'
                    : 'لا يوجد تشخيص مدون.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // 3. العلاج والتعليمات
            Row(
              children: [
                Icon(Icons.medication_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'العلاج والتعليمات الموصوفة (الروشتة):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _instructionsController,
              maxLines: isMobile ? 3 : 3,
              minLines: 2,
              readOnly: !isDoctor,
              style: TextStyle(color: textPrimaryColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: isDoctor 
                    ? 'اكتب العلاج الموصوف، الأدوية، والتعليمات الطبية...'
                    : 'لا يوجد علاج مدون.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 20),
            const SizedBox(height: 1),
            const SizedBox(height: 12),
            Text(
              'الخدمات الطبية المقدمة في هذه الزيارة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondaryColor),
            ),
            const SizedBox(height: 10),
            
            // قائمة الخدمات المتاحة
            availableServicesAsync.when(
              data: (availableList) {
                if (availableList.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'لا توجد خدمات مضافة في الإعدادات بعد.',
                      style: TextStyle(fontSize: 12, color: textSecondaryColor),
                    ),
                  );
                }

                if (!isDoctor) {
                  // عرض الخدمات المحددة فقط للمساعد
                  if (_selectedServices.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'لم يتم تقديم أي خدمات إضافية.',
                        style: TextStyle(fontSize: 12, color: textSecondaryColor),
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedServices.map((service) {
                      return Chip(
                        backgroundColor: badgeBgColor,
                        side: BorderSide.none,
                        label: Text(
                          '${service.name} (${service.price.toStringAsFixed(0)} ج.م)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }

                // الطبيب يستطيع تحديد وتغيير الخدمات
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableList.map((service) {
                    final isSelected = _selectedServices.any((s) => s.id == service.id);
                    return FilterChip(
                      selected: isSelected,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      selectedColor: badgeBgColor,
                      checkmarkColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                      label: Text(
                        '${service.name} (${service.price.toStringAsFixed(0)} ج.م)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Theme.of(context).colorScheme.primary : textPrimaryColor,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedServices.add(service);
                          } else {
                            _selectedServices.removeWhere((s) => s.id == service.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              error: (err, _) => Text(
                'خطأ في تحميل الخدمات: $err',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
          ];

          // ─── تخطيط الصفحة المنقسمة للمكتب ───
          final desktopLayout = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اليمين: ملاحظات الجلسة والخدمات الحالية
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: currentSessionChildren,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 1,
                height: 380,
                color: borderLightColor,
              ),
              const SizedBox(width: 20),
              // اليسار: السجل الطبي للزيارات السابقة
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'السجل الطبي وتاريخ الزيارات:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textSecondaryColor),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 340,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF1E293B) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: historyAsync.when(
                        data: (historyList) {
                          final cleanHistory = historyList.where((n) => n.appointmentId != widget.appointmentId).toList();
                          if (cleanHistory.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'لا توجد زيارات سابقة مسجلة للمريض.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: textSecondaryColor),
                                ),
                              ),
                            );
                          }
                          return ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: cleanHistory.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final hNote = cleanHistory[index];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.event_note_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            hNote.createdAt.toLocal().toString().substring(0, 10),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        hNote.notes,
                                        style: TextStyle(fontSize: 12, color: textPrimaryColor, height: 1.4),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (err, _) => Center(child: Text('خطأ: $err', style: const TextStyle(fontSize: 11, color: Colors.red))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          return ClinicDialog(
            icon: isDoctor ? Icons.medical_information_outlined : Icons.description_outlined,
            title: isDoctor ? 'جلسة فحص وتشخيص المريض' : 'التقرير الطبي للمريض',
            subtitle: 'المريض: ${widget.patientName}',
            maxWidth: isMobile ? 500 : 850,
            content: isMobile 
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: currentSessionChildren,
                  )
                : desktopLayout,
            actions: [
              if (hasExisting && isDoctor)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: _isDeleting
                      ? SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.error),
                        )
                      : const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('حذف الجلسة', style: TextStyle(fontSize: 12)),
                  onPressed: _isDeleting || _isSaving ? null : _delete,
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isDoctor ? 'إلغاء' : 'إغلاق'),
              ),
              if (isDoctor) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : () => _save(hasExisting),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(hasExisting ? 'تحديث' : 'حفظ'),
                ),
              ],
            ],
          );
        },
        loading: () => const Dialog(
          child: SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        error: (err, _) => Dialog(
          child: SizedBox(
            height: 100,
            child: Center(
              child: Text('خطأ في تحميل الملاحظات: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}
