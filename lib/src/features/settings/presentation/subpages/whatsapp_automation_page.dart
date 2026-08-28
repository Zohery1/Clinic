import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
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
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(duration: Duration(seconds: 2), content: Text('تم حفظ إعدادات الأتمتة بنجاح'), backgroundColor: AppTheme.success),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(seconds: 2), content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.error),
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
          title: const Text('إلغاء ربط الواتساب'),
          content: const Text('هل أنت متأكد من رغبتك في إلغاء ربط رقم العيادة وتعطيل الإرسال التلقائي؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                final instName = _whatsappInstanceNameController.text.trim().isNotEmpty
                    ? _whatsappInstanceNameController.text.trim()
                    : (user != null && user.clinicId.length >= 8 ? 'clinic_${user.clinicId.substring(0, 8)}' : '');

                setState(() {
                  _whatsappStatus = 'disconnected';
                  _whatsappEnabled = false;
                  _whatsappPhoneController.clear();
                });

                if (instName.isNotEmpty) {
                  // Delete instance cleanly from Evo Manager, Redis & DB Evo
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
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 2), 
                      content: Text('تم إلغاء ربط الواتساب وحذف الجلسة بنجاح'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('نعم، إلغاء الربط'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final isDoctor = user?.role == UserRole.doctor;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعدادات الواتساب والأتمتة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isConnected = _whatsappStatus == 'connected';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('إعدادات الواتساب والأتمتة'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. كارت حالة الاتصال
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.cardDecoration(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_cell_rounded,
                              color: isConnected ? AppTheme.success : AppTheme.error,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'حالة الاتصال بالبوابة',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isConnected ? AppTheme.success : AppTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isConnected ? 'متصل ومفعّل' : 'غير متصل',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isConnected ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isConnected) ...[
                        TextFormField(
                          controller: _whatsappPhoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.cairo(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'رقم هاتف الواتساب الخاص بالعيادة',
                            hintText: 'أدخل رقم الهاتف...',
                            isDense: true,
                            prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF10B981)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (isDoctor)
                        ElevatedButton(
                          onPressed: isConnected ? _disconnectWhatsapp : _openPairingDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConnected ? theme.colorScheme.error : theme.colorScheme.primary,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isConnected ? 'إلغاء ربط الواتساب' : 'ربط الواتساب الآن (رمز QR / كود رقمي)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. إعدادات الأتمتة الأساسية
                Text(
                  'أتمتة الرسائل التلقائية',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _whatsappEnabled,
                        onChanged: isConnected && isDoctor
                            ? (val) => setState(() => _whatsappEnabled = val)
                            : null,
                        title: const Text('تفعيل خدمة الواتساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال تنبيهات المواعيد للمرضى عبر الواتساب', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendBookingMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendBookingMessage = val)
                            : null,
                        title: const Text('رسالة تأكيد الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة فورية عند حجز موعد جديد للمريض', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendReminderMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendReminderMessage = val)
                            : null,
                        title: const Text('رسالة تذكير بالموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة تذكير تلقائية قبل موعد الزيارة بـ 24 ساعة', style: TextStyle(fontSize: 11)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _sendCancellationMessage,
                        onChanged: _whatsappEnabled && isDoctor
                            ? (val) => setState(() => _sendCancellationMessage = val)
                            : null,
                        title: const Text('رسالة اعتذار عند إلغاء الموعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('إرسال رسالة اعتذار تلقائية للمريض عند إلغاء موعده من قِبل العيادة', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. قوالب الرسائل وتخصيصها
                if (_sendBookingMessage) ...[
                  Text(
                    'قالب رسالة تأكيد الحجز',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bookingTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_bookingTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                if (_sendReminderMessage) ...[
                  Text(
                    'قالب رسالة التذكير بالموعد',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reminderTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_reminderTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                if (_sendCancellationMessage) ...[
                  Text(
                    'قالب رسالة الاعتذار عن إلغاء الموعد',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cancellationTemplateController,
                    enabled: isDoctor,
                    maxLines: 4,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: const InputDecoration(
                      hintText: 'اكتب نص الرسالة هنا...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSmartTagsRow(_cancellationTemplateController, isDoctor),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 20),
                // زر حفظ البيانات
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ إعدادات الأتمتة'),
                ),
                const SizedBox(height: 40),
              ],
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
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? () => _insertTag(controller, tag) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$label $tag',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
