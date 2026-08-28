import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' as intl;

/// شاشة تتبع دور المريض اللحظية في العيادة (Public Patient Queue Tracker)
/// تُفتح عبر رابط الواتساب المرسل للمريض بدون الحاجة لتسجيل الدخول
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
  String? _errorMessage;
  Map<String, dynamic>? _queueData;
  Timer? _autoRefreshTimer;
  DateTime _lastRefreshedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchQueueStatus();
    // تحديث تلقائي كل 15 ثانية لمتابعة حركة الطابور اللحظية
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dynamic response = await Supabase.instance.client.rpc(
        'get_patient_queue_status',
        params: {'p_appointment_id': widget.appointmentId.trim()},
      );

      if (response == null || response['found'] != true) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = response?['message'] ?? 'لم يتم العثور على بيانات هذا الموعد.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _queueData = Map<String, dynamic>.from(response as Map);
          _isLoading = false;
          _errorMessage = null;
          _lastRefreshedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted && !isBackground) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل بيانات الدور: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
          elevation: 0,
          title: Text(
            'متابعة دور الكشف اللحظي',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث الدور الآن',
              onPressed: () => _fetchQueueStatus(),
            ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading && _queueData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'جاري قراءة حالة الدور في العيادة...',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _queueData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 50, color: Colors.red),
              ),
              const SizedBox(height: 16),
              Text(
                'تعذر تحميل الموعد',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _fetchQueueStatus(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final data = _queueData!;
    final patientName = data['patient_name'] as String? ?? 'عزيزي المريض';
    final doctorName = data['doctor_name'] as String? ?? 'طبيب العيادة';
    final clinicName = data['clinic_name'] as String? ?? 'العيادة';
    final branchName = data['branch_name'] as String? ?? 'الفرع الرئيسي';
    final queueNumber = data['queue_number'] as int? ?? 1;
    final patientsAhead = data['patients_ahead'] as int? ?? 0;
    final isCurrent = data['is_current'] == true;
    final isCompleted = data['is_completed'] == true;
    final isCancelled = data['is_cancelled'] == true;

    DateTime? apptDate;
    try {
      if (data['appointment_date'] != null) {
        apptDate = DateTime.parse(data['appointment_date'].toString()).toLocal();
      }
    } catch (_) {}

    return RefreshIndicator(
      onRefresh: () => _fetchQueueStatus(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ─── ترويسة العيادة ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinicName,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                branchName,
                                style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مرحباً بك: $patientName',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    Text(
                      doctorName,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (apptDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'موعد الكشف: ${intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(apptDate)}',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── بطاقة الحالة الرئيسية ───
          if (isCurrent)
            _buildCurrentTurnCard()
          else if (isCompleted)
            _buildCompletedCard()
          else if (isCancelled)
            _buildCancelledCard()
          else
            _buildWaitingQueueCard(queueNumber, patientsAhead),

          const SizedBox(height: 24),

          // ─── مؤشر التحديث التلقائي ───
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'يتم التحديث اللحظي تلقائياً • آخر تحديث: ${intl.DateFormat('hh:mm:ss a').format(_lastRefreshedAt)}',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// بطاقة عند حلول دور المريض مع الطبيب
  Widget _buildCurrentTurnCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.meeting_room_rounded, size: 54, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            'دورك الآن! تفضل بالدخول',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الطبيب في انتظارك الآن في غرفة الكشف. يرجى التوجه للداخل فوراً.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة في حالة الانتظار وحساب المتبقي
  Widget _buildWaitingQueueCard(int queueNumber, int patientsAhead) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String adviceText;
    if (patientsAhead == 0) {
      adviceText = 'أنت التالي مباشرة! يرجى التواجد أمام غرفة الكشف والاستعداد للدخول.';
    } else if (patientsAhead == 1) {
      adviceText = 'متبقي مريض واحد فقط أمامك في غرفة الكشف. استعد للدخول قريباً.';
    } else {
      adviceText = 'متبقي $patientsAhead مرضى قبل دورك. يمكنك الاستراحة في صالة الانتظار.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'رقم دورك',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#$queueNumber',
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'متبقي قبلك',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$patientsAhead',
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (patientsAhead <= 1 ? Colors.green : Colors.blue).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (patientsAhead <= 1 ? Colors.green : Colors.blue).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  patientsAhead <= 1 ? Icons.notification_important_rounded : Icons.info_outline_rounded,
                  color: patientsAhead <= 1 ? Colors.green.shade700 : Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    adviceText,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: patientsAhead <= 1 ? Colors.green.shade800 : Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة انتهاء الكشف
  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 50, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'اكتمل الكشف بنجاح',
            style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'تم الانتهاء من موعدك الطبي. نتمنى لكم دوام الصحة والعافية والشفاء العاجل.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// بطاقة إلغاء الموعد
  Widget _buildCancelledCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            'تم إلغاء هذا الحجز',
            style: GoogleFonts.cairo(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'تم إلغاء هذا الموعد في نظام العيادة. يرجى التواصل مع إدارة العيادة عند وجود أي استفسار.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
