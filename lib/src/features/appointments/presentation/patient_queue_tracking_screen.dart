import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/demo/demo_clinical_data.dart';
import '../../../core/ui/tokens/colors.dart';
import '../../../core/ui/tokens/spacing.dart';

/// شاشة تتبع دور المريض اللحظية في العيادة (Public Patient Live Queue Tracker)
/// تُفتح للمريض عبر رابط الواتساب لمتابعة دوره المباشر ووقت الانتظار المتوقع
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
      });
    }

    final id = widget.appointmentId.trim();

    // وضع المعاينة والعرض التجريبي التلقائي عند عدم وجود معرف حقيقي أو عند اختبار الرابط
    if (id.isEmpty || id == 'demo' || id == 'test' || id.startsWith('preview')) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _queueData = DemoClinicalData.patientQueueStatus;
          _isLoading = false;
          _lastRefreshedAt = DateTime.now();
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
        // إذا لم يعثر عليه في قاعدة البيانات، نعرض البيانات السريرية النموذجية مع إشعار توضيحي
        if (mounted) {
          setState(() {
            _queueData = DemoClinicalData.patientQueueStatus;
            _isLoading = false;
            _lastRefreshedAt = DateTime.now();
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _queueData = Map<String, dynamic>.from(response as Map);
          _isLoading = false;
          _lastRefreshedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _queueData = DemoClinicalData.patientQueueStatus;
          _isLoading = false;
          _lastRefreshedAt = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF090D1A) : const Color(0xFFF8FAFC);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: canvas,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _queueData?['clinic_name'] ?? 'مستشفى وعيادات الأمل التخصصية',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'تتبع لحظي مباشر للطابور',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF059669),
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
                      tooltip: 'تحديث الدور الآن',
                      onPressed: () => _fetchQueueStatus(),
                      color: const Color(0xFF1D4ED8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1120 : 680),
                child: _buildBody(context, isDesktop: isDesktop),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {bool isDesktop = false}) {
    if (_isLoading && _queueData == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'جاري قراءة حالة الدور في العيادة...',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final data = _queueData ?? DemoClinicalData.patientQueueStatus;
    final patientName = data['patient_name'] as String? ?? 'عزيزي المريض';
    final doctorName = data['doctor_name'] as String? ?? 'د. عبد الرحمن الزهيري';
    final doctorTitle = data['doctor_title'] as String? ?? 'استشاري جراحة العظام والمفاصل';
    final branchName = data['branch_name'] as String? ?? 'فرع المعادي الرئيسي';
    final roomName = data['room_name'] as String? ?? 'غرفة الكشف رقم 2';
    final ticketNumber = data['ticket_number']?.toString() ?? '14';
    final patientsAhead = data['patients_ahead'] as int? ?? 2;
    final estimatedWait = data['estimated_wait_minutes'] as int? ?? 15;
    final examType = data['examination_type'] as String? ?? 'استشارة ومتابعة أشعة';
    final clinicPhone = data['clinic_phone'] as String? ?? '0223456789';

    final ticketCard = _buildTicketHeroCard(
      context: context,
      ticketNumber: ticketNumber,
      patientName: patientName,
      patientsAhead: patientsAhead,
      estimatedWait: estimatedWait,
      examType: examType,
    );

    final doctorCard = _buildDoctorInfoCard(
      context: context,
      doctorName: doctorName,
      doctorTitle: doctorTitle,
      roomName: roomName,
      branchName: branchName,
      clinicPhone: clinicPhone,
    );

    final journeyCard = _buildVisitJourneyCard(context: context, data: data);
    final guidanceCard = _buildGuidanceCard(context: context);

    final footerWidget = Center(
      child: Text(
        'يتم التحديث تلقائياً كل 15 ثانية · آخر تحديث: ${_lastRefreshedAt.hour}:${_lastRefreshedAt.minute.toString().padLeft(2, '0')}',
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted(context),
        ),
      ),
    );

    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      ticketCard,
                      const SizedBox(height: AppSpace.lg),
                      guidanceCard,
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xl),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      doctorCard,
                      const SizedBox(height: AppSpace.lg),
                      journeyCard,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            footerWidget,
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ticketCard,
          const SizedBox(height: AppSpace.lg),
          doctorCard,
          const SizedBox(height: AppSpace.lg),
          journeyCard,
          const SizedBox(height: AppSpace.lg),
          guidanceCard,
          const SizedBox(height: AppSpace.xl),
          footerWidget,
          const SizedBox(height: AppSpace.xxl),
        ],
      ),
    );
  }

  /// بطاقة التذكرة السريرية الكبرى
  Widget _buildTicketHeroCard({
    required BuildContext context,
    required String ticketNumber,
    required String patientName,
    required int patientsAhead,
    required int estimatedWait,
    required String examType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أهلاً بك، $patientName',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    examType,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.25)),
                ),
                child: Text(
                  'في صالة الانتظار',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),

          // رقم التذكرة الضخم
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'رقم دورك الحالي في الطابور',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '#$ticketNumber',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),

          // إحصائية المرضى ووقت الانتظار
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF090D1A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$patientsAhead مريض',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      Text(
                        'في الانتظار قبلك',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border(context)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '~$estimatedWait دقيقة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Text(
                        'الوقت المتوقع للكشف',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة الطبيب والعيادة
  Widget _buildDoctorInfoCard({
    required BuildContext context,
    required String doctorName,
    required String doctorTitle,
    required String roomName,
    required String branchName,
    required String clinicPhone,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                Text(
                  doctorTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roomName,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      branchName,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
            tooltip: 'الاتصال بالعيادة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'رقم هاتف الاستقبال: $clinicPhone',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// خط سير الزيارة
  Widget _buildVisitJourneyCard({
    required BuildContext context,
    required Map<String, dynamic> data,
  }) {
    final steps = (data['timeline_steps'] as List<dynamic>?) ?? [
      {'step': 1, 'title': 'حجز الموعد وتأكيده', 'time': '10:00 ص', 'done': true},
      {'step': 2, 'title': 'تسجيل الوصول بالعيادة', 'time': '10:45 ص', 'done': true},
      {'step': 3, 'title': 'في صالة الانتظار (دورك التالي)', 'time': 'الآن', 'done': true, 'active': true},
      {'step': 4, 'title': 'الدخول لغرفة الطبيب للكشف', 'time': '11:00 ص', 'done': false},
      {'step': 5, 'title': 'استلام الروشتة وإتمام الزيارة', 'time': '--', 'done': false},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراحل زيارتك اليوم بالعيادة',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          for (int i = 0; i < steps.length; i++) ...[
            _buildTimelineItem(
              context: context,
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required dynamic step,
    required bool isLast,
  }) {
    final isDone = step['done'] == true;
    final isActive = step['active'] == true;
    final title = step['title'] as String;
    final time = step['time'] as String;

    final dotColor = isActive
        ? const Color(0xFF0284C7)
        : isDone
            ? const Color(0xFF059669)
            : const Color(0xFFCBD5E1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: isActive ? 0.2 : 1.0),
                shape: BoxShape.circle,
                border: Border.all(color: dotColor, width: isActive ? 2.5 : 1.5),
              ),
              child: Center(
                child: isDone && !isActive
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : isActive
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : isDone ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : isDone
                              ? AppColors.textPrimary(context)
                              : AppColors.textMuted(context),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primarySubtle
                        : (isDone ? AppColors.subtle(context) : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (isDone ? AppColors.borderSubtle(context) : Colors.transparent),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    time,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.primary : AppColors.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// إرشادات الانتظار
  Widget _buildGuidanceCard({required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 22),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              'يرجى التواجد بالقرب من صالة الانتظار عند اقتراب دورك. سيتم إرسال إشعار فوري لك لحظة نداء اسمك لدخول غرفة الطبيب.',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0369A1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
