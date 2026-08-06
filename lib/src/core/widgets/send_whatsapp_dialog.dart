import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/auth/presentation/login_controller.dart';
import '../../features/settings/data/whatsapp_service.dart';
import '../theme/app_theme.dart';

void showSendWhatsAppDialog(
  BuildContext context,
  WidgetRef ref, {
  required String phone,
  required String patientName,
}) {
  showDialog(
    context: context,
    builder: (context) => SendWhatsAppDialog(
      phone: phone,
      patientName: patientName,
    ),
  );
}

class SendWhatsAppDialog extends ConsumerStatefulWidget {
  final String phone;
  final String patientName;

  const SendWhatsAppDialog({
    super.key,
    required this.phone,
    required this.patientName,
  });

  @override
  ConsumerState<SendWhatsAppDialog> createState() => _SendWhatsAppDialogState();
}

class _SendWhatsAppDialogState extends ConsumerState<SendWhatsAppDialog> {
  late TextEditingController _messageController;
  bool _isSending = false;

  final List<String> _quickTemplates = [
    'عزيزي المريض [name]، نتمنى لكم دوام الصحة والعافية.',
    'عزيزي المريض [name]، نود تذكيركم بموعدكم القادم في العيادة.',
    'عزيزي المريض [name]، نرجو التكرم بالتواصل مع العيادة للاطمئنان على حالتكم.',
    'عزيزي المريض [name]، نتائج الفحوصات والتحاليل الخاصة بكم جاهزة في العيادة.',
  ];

  @override
  void initState() {
    super.initState();
    final defaultMsg = _quickTemplates[0].replaceAll('[name]', widget.patientName);
    _messageController = TextEditingController(text: defaultMsg);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _cleanPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('0')) {
      clean = '20${clean.substring(1)}';
    } else if (!clean.startsWith('20')) {
      clean = '20$clean';
    }
    return clean;
  }

  Future<void> _openInWhatsAppApp() async {
    final clean = _cleanPhone(widget.phone);
    final text = Uri.encodeComponent(_messageController.text.trim());
    final url = Uri.parse('https://wa.me/$clean?text=$text');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الواتساب')),
        );
      }
    }
  }

  Future<void> _sendViaApi() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الرسالة')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null || user.clinicId.isEmpty) {
      _openInWhatsAppApp();
      return;
    }

    setState(() => _isSending = true);

    final success = await ref.read(whatsappServiceProvider).sendCustomMessage(
          clinicId: user.clinicId,
          phone: widget.phone,
          message: msg,
        );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('تم إرسال الرسالة إلى ${widget.patientName} بنجاح!')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        // Fallback to opening WhatsApp Web/App if API sending is disabled
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(
            content: Text('خدمة الرسائل التلقائية غير مفعّلة بالعيادة، يتم الآن فتح الواتساب مباشر...'),
            backgroundColor: Colors.orange,
          ),
        );
        _openInWhatsAppApp();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إرسال رسالة واتساب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المريض: ${widget.patientName} (${widget.phone})',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick template chips
              Text(
                'نماذج رسائل سريعة:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildChip('تواصل واطمئنان', 0),
                  _buildChip('تذكير بموعد', 1),
                  _buildChip('متابعة حالة', 2),
                  _buildChip('استلام فحوصات', 3),
                ],
              ),
              const SizedBox(height: 16),

              // Message field
              TextField(
                controller: _messageController,
                maxLines: 4,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب نص الرسالة هنا...',
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendViaApi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSending ? 'جاري الإرسال...' : 'إرسال عبر النظام 🚀',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _openInWhatsAppApp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF10B981), size: 18),
                    label: Text(
                      'فتح الواتساب 🌐',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    return InkWell(
      onTap: () {
        final text = _quickTemplates[index].replaceAll('[name]', widget.patientName);
        _messageController.text = text;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
