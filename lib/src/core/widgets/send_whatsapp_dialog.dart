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
  late TextEditingController _phoneController;
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
    _messageController = TextEditingController(text: '');
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
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
    final targetPhone = _phoneController.text.trim();
    if (targetPhone.isEmpty) return;
    final clean = _cleanPhone(targetPhone);
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
    final targetPhone = _phoneController.text.trim();
    if (targetPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رقم الهاتف')),
      );
      return;
    }

    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الرسالة')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    Navigator.pop(context); // إغلاق النافذة فوراً لتجربة سريعة وبدون أي انتظار

    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('جاري إرسال الرسالة إلى ${widget.patientName}...')),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );

    if (user != null && user.clinicId.isNotEmpty) {
      final success = await ref.read(whatsappServiceProvider).sendCustomMessage(
            clinicId: user.clinicId,
            phone: targetPhone,
            message: msg,
          );

      if (!success) {
        _openInWhatsAppApp();
      }
    } else {
      _openInWhatsAppApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          width: screenWidth > 560 ? 520 : screenWidth * 0.92,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: SingleChildScrollView(
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
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إرسال رسالة واتساب',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'المريض: ${widget.patientName} (${widget.phone})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 16),

                // Phone number field
                Text(
                  'رقم الهاتف المراد الإرسال إليه:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.cairo(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم الواتساب...',
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF10B981)),
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
                const SizedBox(height: 14),

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
                const SizedBox(height: 14),

                // Message field
                TextField(
                  controller: _messageController,
                  maxLines: isSmallScreen ? 3 : 4,
                  style: GoogleFonts.cairo(fontSize: 13),
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
                const SizedBox(height: 20),

                // Buttons (Responsive Layout)
                isSmallScreen
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _sendViaApi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                'إرسال',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _openInWhatsAppApp,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFF10B981)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF10B981), size: 18),
                              label: Text(
                                'فتح الواتساب',
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendViaApi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                'إرسال',
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
                              'فتح الواتساب',
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
