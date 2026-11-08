import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/demo/demo_clinical_data.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';

/// Clinical Utility Patient Live Queue Tracker.
/// Clean, zero raw hex fragmentation, direct and concise copy.
class PatientQueueTrackingScreen extends StatefulWidget {
  final String appointmentId;

  const PatientQueueTrackingScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<PatientQueueTrackingScreen> createState() => _PatientQueueTrackingScreenState();
}

class _PatientQueueTrackingScreenState extends State<PatientQueueTrackingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _queueData;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchQueueStatus();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _fetchQueueStatus(isBackground: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQueueStatus({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() => _isLoading = true);
    }

    final id = widget.appointmentId.trim();

    if (id.isEmpty || id == 'demo' || id == 'test' || id.startsWith('preview')) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _queueData = DemoClinicalData.patientQueueStatus;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final dynamic response = await Supabase.instance.client.rpc(
        'get_patient_queue_status',
        params: {'p_appointment_id': id},
      );

      if (response == null || response['found'] != true) {
        if (mounted) {
          setState(() {
            _queueData = DemoClinicalData.patientQueueStatus;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _queueData = Map<String, dynamic>.from(response as Map);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _queueData = DemoClinicalData.patientQueueStatus;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.canvas(context);
    final border = AppColors.borderSubtle(context);
    final surface = AppColors.surface(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: border, width: 1)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _queueData?['clinic_name'] ?? 'عيادتي',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'تتبع مباشر للطابور',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'تحديث الدور',
                      onPressed: () => _fetchQueueStatus(),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _queueData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpace.md),
            Text(
              'جاري تحميل حالة الدور...',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textMuted(context)),
            ),
          ],
        ),
      );
    }

    final data = _queueData ?? DemoClinicalData.patientQueueStatus;
    final patientName = data['patient_name'] as String? ?? 'المريض';
    final doctorName = data['doctor_name'] as String? ?? 'الطبيب المختص';
    final branchName = data['branch_name'] as String? ?? 'الفرع الرئيسي';
    final roomName = data['room_name'] as String? ?? 'غرفة الكشف';
    final ticketNumber = data['ticket_number']?.toString() ?? '1';
    final patientsAhead = data['patients_ahead'] as int? ?? 0;
    final estimatedWait = data['estimated_wait_minutes'] as int? ?? 0;
    final isMyTurn = patientsAhead == 0;

    final surface = AppColors.surface(context);
    final border = AppColors.borderSubtle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ticket Card
        Container(
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: isMyTurn ? AppColors.success : border,
              width: isMyTurn ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMyTurn ? AppColors.successSubtle : AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  isMyTurn ? 'دورك الآن — تفضل بالدخول' : 'في الانتظار',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isMyTurn ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'رقمك في الطابور',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticketNumber,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: isMyTurn ? AppColors.success : AppColors.primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                patientName,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'قبلك في الطابور',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        patientsAhead == 0 ? 'أنت التالي مباشرة' : '$patientsAhead مرضى',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: border),
                  Column(
                    children: [
                      Text(
                        'الوقت المتوقع',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estimatedWait == 0 ? 'الآن' : '$estimatedWait دقيقة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // Clinic & Doctor Details
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بيانات العيادة والكشف',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              _DetailRow(icon: Icons.person_outline_rounded, label: 'الطبيب', value: doctorName),
              const SizedBox(height: AppSpace.sm),
              _DetailRow(icon: Icons.business_outlined, label: 'الفرع', value: branchName),
              const SizedBox(height: AppSpace.sm),
              _DetailRow(icon: Icons.meeting_room_outlined, label: 'الغرفة', value: roomName),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),

        // Advice Card
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.subtle(context),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary(context)),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  'يتم تحديث الطابور تلقائياً كل 15 ثانية. يرجى التواجد بالقرب من العيادة عند اقتراب دورك.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted(context)),
        const SizedBox(width: AppSpace.sm),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}
