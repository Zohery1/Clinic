import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/auth/presentation/login_controller.dart';
import '../../features/settings/data/whatsapp_service.dart';
import '../ui/tokens/colors.dart';
import '../ui/tokens/spacing.dart';

void showSendWhatsAppDialog(
  BuildContext context,
  WidgetRef ref, {
  required String phone,
  required String patientName,
  String? initialMessage,
}) {
  showDialog(
    context: context,
    builder: (context) => SendWhatsAppDialog(
      phone: phone,
      patientName: patientName,
      initialMessage: initialMessage,
    ),
  );
}

class SendWhatsAppDialog extends ConsumerStatefulWidget {
  final String phone;
  final String patientName;
  final String? initialMessage;

  const SendWhatsAppDialog({
    super.key,
    required this.phone,
    required this.patientName,
    this.initialMessage,
  });

  @override
  ConsumerState<SendWhatsAppDialog> createState() => _SendWhatsAppDialogState();
}

class _SendWhatsAppDialogState extends ConsumerState<SendWhatsAppDialog> {
  late TextEditingController _messageController;
  late TextEditingController _phoneController;

  final List<String> _quickTemplates = [
    'عزيزي [name]، نذكركم بموعدكم القادم في العيادة.',
    'عزيزي [name]، نتائج الفحوصات جاهزة بالعيادة.',
    'عزيزي [name]، نتمنى لكم دوام الصحة والعافية.',
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialMessage ?? '');
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
    Navigator.pop(context);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('جاري إرسال الرسالة إلى ${widget.patientName}...'),
          backgroundColor: AppColors.success,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        backgroundColor: AppColors.surface(context),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(AppSpace.xl),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إرسال رسالة واتساب',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          Text(
                            'المريض: ${widget.patientName}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textMuted(context),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),

                // Phone input
                Text(
                  'رقم الهاتف',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.cairo(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'رقم الهاتف...',
                    prefixIcon: Icon(Icons.phone_rounded, size: 18),
                    prefixIconConstraints: BoxConstraints(minWidth: 36),
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // Quick Templates
                Text(
                  'نماذج سريعة',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted(context),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickTemplates.map((template) {
                    final preview = template.replaceAll('[name]', widget.patientName);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _messageController.text = preview;
                        });
                      },
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.subtle(context),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: AppColors.borderSubtle(context), width: 1),
                        ),
                        child: Text(
                          preview.length > 30 ? '${preview.substring(0, 30)}...' : preview,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpace.md),

                // Message Text
                Text(
                  'نص الرسالة',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  style: GoogleFonts.cairo(fontSize: 13.5),
                  decoration: const InputDecoration(
                    hintText: 'اكتب نص الرسالة هنا...',
                  ),
                ),
                const SizedBox(height: AppSpace.lg),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _sendViaApi,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          'إرسال',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
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
}
