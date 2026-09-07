import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../data/whatsapp_service.dart';
import '../widgets/whatsapp_pairing_dialog.dart';

class WhatsAppAutomationPage extends ConsumerStatefulWidget {
  const WhatsAppAutomationPage({super.key});

  @override
  ConsumerState<WhatsAppAutomationPage> createState() => _WhatsAppAutomationPageState();
}

class _WhatsAppAutomationPageState extends ConsumerState<WhatsAppAutomationPage> {
  final _formKey = GlobalKey<FormState>();

  final _whatsappPhoneController = TextEditingController();
  final _whatsappInstanceNameController = TextEditingController();
  final _bookingTemplateController = TextEditingController();
  final _reminderTemplateController = TextEditingController();
  final _cancellationTemplateController = TextEditingController();

  bool _whatsappEnabled = false;
  bool _sendBookingMessage = true;
  bool _sendReminderMessage = true;
  bool _sendCancellationMessage = true;
  String _whatsappStatus = 'disconnected';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select()
          .eq('id', user.clinicId)
          .single();

      setState(() {
        _whatsappEnabled = res['whatsapp_enabled'] as bool? ?? false;
        _whatsappPhoneController.text = res['whatsapp_phone'] as String? ?? '';
        _whatsappInstanceNameController.text = res['whatsapp_instance_name'] as String? ?? '';
        _whatsappStatus = res['whatsapp_status'] as String? ?? 'disconnected';
        _sendBookingMessage = res['send_booking_message'] as bool? ?? true;
        _sendReminderMessage = res['send_reminder_message'] as bool? ?? true;
        _sendCancellationMessage = res['send_cancellation_message'] as bool? ?? true;
        final dbBookingTemplate = res['booking_message_template'] as String?;
        _bookingTemplateController.text = (dbBookingTemplate != null && dbBookingTemplate.isNotEmpty)
            ? dbBookingTemplate
            : 'عزيزي المريض [patient_name]، تم تسجيل حجزك في العيادة لدى [doctor_name] ([branch_name]) بتاريخ [date] في تمام الساعة [time]. لمتابعة دورك في العيادة مباشرة: [queue_link]';

        final dbReminderTemplate = res['reminder_message_template'] as String?;
        _reminderTemplateController.text = (dbReminderTemplate != null && dbReminderTemplate.isNotEmpty)
            ? dbReminderTemplate
            : 'تذكير: عزيزي المريض [patient_name]، موعد كشفك القادم لدى [doctor_name] ([branch_name]) هو غداً [date] في تمام الساعة [time]. لمتابعة دورك في العيادة: [queue_link]';

        final dbCancelTemplate = res['cancellation_message_template'] as String?;
        _cancellationTemplateController.text = (dbCancelTemplate != null && dbCancelTemplate.isNotEmpty)
            ? dbCancelTemplate
            : 'عزيزي المريض [patient_name]، نعتذر عن إلغاء موعدك لدى [doctor_name] ([branch_name]) بتاريخ [date] لظروف طارئة بالعيادة. نتمنى لكم دوام الصحة والعافية.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _whatsappPhoneController.dispose();
    _whatsappInstanceNameController.dispose();
    _bookingTemplateController.dispose();
    _reminderTemplateController.dispose();
    _cancellationTemplateController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        await Supabase.instance.client
            .from('clinics')
            .update({
              'whatsapp_enabled': _whatsappEnabled,
              'whatsapp_phone': _whatsappPhoneController.text.trim(),
              'whatsapp_status': _whatsappStatus,
              'send_booking_message': _sendBookingMessage,
              'send_reminder_message': _sendReminderMessage,
              'send_cancellation_message': _sendCancellationMessage,
              'booking_message_template': _bookingTemplateController.text.trim(),
              'reminder_message_template': _reminderTemplateController.text.trim(),
              'cancellation_message_template': _cancellationTemplateController.text.trim(),
            })
            .eq('id', user.clinicId);

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text('تم حفظ إعدادات الأتمتة بنجاح', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.success,
              ),
            );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                content: Text('خطأ أثناء الحفظ: $e', style: GoogleFonts.cairo()),
                backgroundColor: AppColors.danger,
              ),
            );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _insertTag(TextEditingController controller, String tag) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, tag);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + tag.length);
    } else {
      controller.text = text + tag;
    }
  }

  void _openPairingDialog() {
    WhatsAppPairingDialog.show(
      context,
      initialPhone: _whatsappPhoneController.text,
      onConnected: (connectedPhone, activeInstanceName) {
        setState(() {
          _whatsappStatus = 'connected';
          _whatsappEnabled = true;
          _whatsappInstanceNameController.text = activeInstanceName;
          _whatsappPhoneController.text = connectedPhone;
        });
      },
    );
  }

  void _disconnectWhatsapp() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'إلغاء ربط الواتساب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في إلغاء ربط رقم العيادة وتعطيل الإرسال التلقائي؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'تراجع',
                style: GoogleFonts.cairo(color: AppColors.textSecondary(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: AppColors.onPrimary,
              ),
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                final instName = _whatsappInstanceNameController.text.trim().isNotEmpty
                    ? _whatsappInstanceNameController.text.trim()
                    : (user != null && user.clinicId.length >= 8
                        ? 'clinic_${user.clinicId.substring(0, 8)}'
                        : '');

                setState(() {
                  _whatsappStatus = 'disconnected';
                  _whatsappEnabled = false;
                  _whatsappPhoneController.clear();
                });

                if (instName.isNotEmpty) {
                  await ref.read(whatsappServiceProvider).deleteInstance(instName);
                }

                if (user != null) {
                  await Supabase.instance.client
                      .from('clinics')
                      .update({
                        'whatsapp_status': 'disconnected',
                        'whatsapp_enabled': false,
                        'whatsapp_phone': null,
                        'whatsapp_instance_name': null,
                      })
                      .eq('id', user.clinicId);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 2),
                        content: Text(
                          'تم إلغاء ربط الواتساب وحذف الجلسة بنجاح',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                }
              },
              child: Text('نعم، إلغاء الربط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;
    final isDark = AppColors.isDark(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'إعدادات الواتساب والأتمتة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isConnected = _whatsappStatus == 'connected';
    final statusColor = isConnected ? AppColors.success : AppColors.danger;
    final statusBg = isDark
        ? statusColor.withValues(alpha: 0.15)
        : (isConnected ? AppColors.successSubtle : AppColors.dangerSubtle);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'إعدادات الواتساب والأتمتة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. كارت حالة الاتصال
                Container(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderSubtle(context),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_cell_rounded,
                              color: statusColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpace.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'حالة الاتصال بالبوابة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isConnected ? 'متصل ومفعّل' : 'غير متصل',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isConnected) ...[
                        const SizedBox(height: AppSpace.lg),
                        Divider(height: 1, color: AppColors.borderSubtle(context)),
                        const SizedBox(height: AppSpace.md),
                        if (_whatsappPhoneController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Text(
                                  'رقم الهاتف المتصل:',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                                const Spacer(),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    _whatsappPhoneController.text,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_whatsappInstanceNameController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.fingerprint_rounded,
                                    size: 16, color: AppColors.textSecondary(context)),
                                const SizedBox(width: 8),
                                Text(
                                  'معرّف الجلسة (Instance ID):',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                                const Spacer(),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    _whatsappInstanceNameController.text,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpace.lg),
                      if (!isConnected) ...[
                        TextFormField(
                          controller: _whatsappPhoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                          decoration: InputDecoration(
                            labelText: 'رقم هاتف الواتساب الخاص بالعيادة',
                            labelStyle: GoogleFonts.cairo(fontSize: 12),
                            hintText: 'أدخل رقم الهاتف...',
                            hintStyle: GoogleFonts.cairo(fontSize: 12),
                            isDense: true,
                            prefixIcon: const Icon(Icons.phone_rounded,
                                size: 18, color: AppColors.success),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                      ],
                      if (isDoctor)
                        ElevatedButton(
                          onPressed: isConnected ? _disconnectWhatsapp : _openPairingDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConnected ? AppColors.danger : AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text(
                            isConnected
                                ? 'إلغاء ربط الواتساب'
                                : 'ربط الواتساب الآن (رمز QR / كود رقمي)',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),

                // 2. إعدادات الأتمتة الأساسية
                Text(
                  'أتمتة الرسائل التلقائية',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderSubtle(context),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _whatsappEnabled,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                        onChanged: isConnected && isDoctor
                            ? (val) => setState(() => _whatsappEnabled = val)
                            : null,
                        title: Text(
                          'تفعيل خدمة الواتساب',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          'إرسال تنبيهات المواعيد للمرضى عبر الواتساب',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderSubtle(context)),
                      SwitchListTile(
                        value: _sendBookingMessage,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendBookingMessage = val)
                            : null,
                        title: Text(
                          'رسالة تأكيد الحجز',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          'إرسال رسالة فورية عند حجز موعد جديد للمريض',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderSubtle(context)),
                      SwitchListTile(
                        value: _sendReminderMessage,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendReminderMessage = val)
                            : null,
                        title: Text(
                          'رسالة تذكير بالموعد',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          'إرسال رسالة تذكير تلقائية قبل موعد الزيارة بـ 24 ساعة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.borderSubtle(context)),
                      SwitchListTile(
                        value: _sendCancellationMessage,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: Colors.white,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendCancellationMessage = val)
                            : null,
                        title: Text(
                          'رسالة اعتذار عند إلغاء الموعد',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        subtitle: Text(
                          'إرسال رسالة اعتذار تلقائية للمريض عند إلغاء موعده من قِبل العيادة',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.xxl),

                // 4. قوالب الرسائل وتخصيصها
                if (_sendBookingMessage) ...[
                  Text(
                    'قالب رسالة تأكيد الحجز',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bookingTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                      hintStyle: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_bookingTemplateController, isDoctor),
                  const SizedBox(height: AppSpace.xl),
                ],

                if (_sendReminderMessage) ...[
                  Text(
                    'قالب رسالة التذكير بالموعد',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reminderTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                      hintStyle: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_reminderTemplateController, isDoctor),
                  const SizedBox(height: AppSpace.xl),
                ],

                if (_sendCancellationMessage) ...[
                  Text(
                    'قالب رسالة الاعتذار عن إلغاء الموعد',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cancellationTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                      hintStyle: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_cancellationTemplateController, isDoctor),
                  const SizedBox(height: AppSpace.xl),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.md,
            bottom: AppSpace.md + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle(context)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                _isSaving ? 'جاري الحفظ...' : 'حفظ إعدادات الأتمتة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartTagsRow(TextEditingController controller, bool enabled) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTagBadge(controller, '[patient_name]', 'اسم المريض', enabled),
        _buildTagBadge(controller, '[date]', 'التاريخ', enabled),
        _buildTagBadge(controller, '[time]', 'وقت الموعد', enabled),
        _buildTagBadge(controller, '[doctor_name]', 'الطبيب المعالج', enabled),
        _buildTagBadge(controller, '[branch_name]', 'الفرع', enabled),
        _buildTagBadge(controller, '[queue_link]', 'رابط متابعة الدور', enabled),
      ],
    );
  }

  Widget _buildTagBadge(TextEditingController controller, String tag, String label, bool enabled) {
    final isDark = AppColors.isDark(context);
    final badgeBg = isDark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primarySubtle;

    return InkWell(
      onTap: enabled ? () => _insertTag(controller, tag) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$label $tag',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
