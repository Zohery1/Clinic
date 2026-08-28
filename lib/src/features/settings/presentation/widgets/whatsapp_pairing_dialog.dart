import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';


import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../data/whatsapp_service.dart';

class WhatsAppPairingDialog extends ConsumerStatefulWidget {
  final String initialPhone;
  final Function(String phone, String instanceName) onConnected;

  const WhatsAppPairingDialog({
    super.key,
    required this.initialPhone,
    required this.onConnected,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialPhone,
    required Function(String phone, String instanceName) onConnected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WhatsAppPairingDialog(
        initialPhone: initialPhone,
        onConnected: onConnected,
      ),
    );
  }

  @override
  ConsumerState<WhatsAppPairingDialog> createState() => _WhatsAppPairingDialogState();
}

class _WhatsAppPairingDialogState extends ConsumerState<WhatsAppPairingDialog> {
  int _selectedMethodTab = 0;
  String? _qrBase64;
  String? _pairingCode;
  bool _isLoadingQr = true;
  bool _isLoadingPairing = false;
  String? _qrError;
  String? _pairingError;
  late String _instanceName;
  late TextEditingController _pairingPhoneController;
  Timer? _pollTimer;
  bool _isConnectedSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _instanceName = user != null
        ? 'clinic_${user.clinicId.replaceAll('-', '_').substring(0, 8)}'
        : 'clinic_default';
    _pairingPhoneController = TextEditingController(text: widget.initialPhone);
    _loadQr();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pairingPhoneController.dispose();
    super.dispose();
  }

  void _checkStatus() async {
    if (_isConnectedSuccess) return;
    try {
      final statusRes = await ref.read(whatsappServiceProvider).checkEvolutionStatus(_instanceName);
      if (statusRes != null && statusRes['connectionStatus'] == 'open') {
        _isConnectedSuccess = true;
        _pollTimer?.cancel();

        String connectedPhone = _pairingPhoneController.text;
        if (statusRes['phone'] != null) {
          String p = statusRes['phone'].toString();
          if (p.startsWith('201') && p.length == 12) {
            connectedPhone = '01${p.substring(3)}';
          } else {
            connectedPhone = p;
          }
        }

        final user = ref.read(currentUserProvider);
        if (user != null) {
          await Supabase.instance.client
              .from('clinics')
              .update({
                'whatsapp_status': 'connected',
                'whatsapp_enabled': true,
                'whatsapp_instance_name': _instanceName,
                'whatsapp_phone': connectedPhone,
              })
              .eq('id', user.clinicId);
        }

        widget.onConnected(connectedPhone, _instanceName);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 3),
              content: Text(connectedPhone.isNotEmpty
                  ? 'تم ربط حساب الواتساب بنجاح! رقم العيادة: $connectedPhone'
                  : 'تم ربط حساب الواتساب بنجاح وتفعيل الأتمتة'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _loadQr() async {
    setState(() {
      _isLoadingQr = true;
      _qrError = null;
    });

    try {
      final res = await ref.read(whatsappServiceProvider).fetchEvolutionQr(_instanceName);

      if (res != null) {
        final data = res;
        String? fetchedQr;
        String? fetchedPairing;

        if (data['base64'] != null) {
          fetchedQr = data['base64'] as String;
        } else if (data['code'] != null) {
          fetchedQr = data['code'] as String;
        }

        final rawPairing = (data['pairingCode'] ?? data['pairing_code'])?.toString();
        if (rawPairing != null && rawPairing.trim().length <= 12 && !rawPairing.contains('/') && !rawPairing.contains('=')) {
          fetchedPairing = rawPairing.trim();
        }

        if (data['qrcode'] != null && data['qrcode']['base64'] != null) {
          fetchedQr = data['qrcode']['base64'] as String;
        }

        if (fetchedQr != null || fetchedPairing != null) {
          setState(() {
            if (fetchedQr != null) _qrBase64 = fetchedQr;
            if (fetchedPairing != null) _pairingCode = fetchedPairing;
            _isLoadingQr = false;
          });
          _pollTimer?.cancel();
          _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
        } else {
          setState(() {
            _isLoadingQr = false;
            _qrError = data['error'] != null ? '${data['error']}' : 'في انتظار تهيئة الجلسة بالبوابة...';
          });
        }
      } else {
        setState(() {
          _isLoadingQr = false;
          _qrError = 'لم يتم الحصول على بيانات الجلسة';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingQr = false;
        _qrError = 'خطأ في الاتصال بالبوابة: $e';
      });
    }
  }

  void _loadPairing() async {
    final phoneInput = _pairingPhoneController.text.trim();
    if (phoneInput.isEmpty) {
      setState(() {
        _pairingError = 'يرجى كتابة رقم هاتف العيادة على الواتساب أولاً';
      });
      return;
    }

    setState(() {
      _isLoadingPairing = true;
      _pairingError = null;
    });

    try {
      final res = await ref.read(whatsappServiceProvider).fetchEvolutionPairingCode(
            instanceName: _instanceName,
            phone: phoneInput,
          );

      if (res != null) {
        if (res['pairingCode'] != null) {
          String p = res['pairingCode'].toString();
          if (p.length == 8) {
            p = '${p.substring(0, 4)} - ${p.substring(4)}';
          }
          setState(() {
            _pairingCode = p;
            _isLoadingPairing = false;
          });
          _pollTimer?.cancel();
          _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
        } else if (res['error'] != null) {
          setState(() {
            _isLoadingPairing = false;
            _pairingError = res['error'].toString();
          });
        } else {
          setState(() {
            _isLoadingPairing = false;
            _pairingError = 'لم يتم تلقي كود الاقتران من البوابة';
          });
        }
      } else {
        setState(() {
          _isLoadingPairing = false;
          _pairingError = 'تعذر الحصول على كود الاقتران من سيرفر الواتساب';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPairing = false;
        _pairingError = 'خطأ في الاتصال: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: (_, __) => _pollTimer?.cancel(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'ربط حساب الواتساب الخاص بالعيادة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedMethodTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedMethodTab == 0 ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'رمز QR (كمبيوتر)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedMethodTab == 0 ? Colors.white : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedMethodTab = 1);
                            if (_pairingCode == null && !_isLoadingPairing && _pairingPhoneController.text.trim().isNotEmpty) {
                              _loadPairing();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedMethodTab == 1 ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'كود رقمي (نفس الموبايل)',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedMethodTab == 1 ? Colors.white : theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_selectedMethodTab == 0) ...[
                  Text(
                    'امسح الرمز المربع من تطبيق WhatsApp بهاتفك (الأجهزة المرتبطة > ربط جهاز)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: _isLoadingQr
                        ? const Center(child: CircularProgressIndicator())
                        : (_qrBase64 != null && _qrBase64!.isNotEmpty)
                            ? Image.memory(
                                base64Decode(_qrBase64!.replaceFirst(RegExp(r'data:image\/[a-zA-Z]+;base64,'), '')),
                                fit: BoxFit.contain,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    _qrError ?? 'اضغط لإعادة التوليد',
                                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  IconButton(
                                    onPressed: _loadQr,
                                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                                  ),
                                ],
                              ),
                  ),
                ] else ...[
                  Text(
                    'افتح تطبيق WhatsApp من هاتفك (الأجهزة المرتبطة > ربط جهاز > الربط برقم الهاتف) وادخل الكود التالي:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 14),

                  // Phone input row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pairingPhoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.cairo(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'رقم هاتف الواتساب',
                            hintText: 'أدخل رقم الهاتف...',
                            isDense: true,
                            prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoadingPairing ? null : _loadPairing,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'توليد الكود',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingPairing)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('جاري طلب كود الاقتران من الواتساب...'),
                        ],
                      ),
                    )
                  else if (_pairingCode != null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: SelectableText(
                            _pairingCode!,
                            style: GoogleFonts.cairo(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            final cleanCode = _pairingCode!.replaceAll(' ', '').replaceAll('-', '');
                            Clipboard.setData(ClipboardData(text: cleanCode));
                            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ كود الاقتران إلى الحافظة!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text(
                            'نسخ الكود',
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    )
                  else if (_pairingError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _pairingError!,
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Text(
                      'أدخل رقم الواتساب ثم اضغط "توليد الكود" لربط الهاتف بدون مسح QR',
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _selectedMethodTab == 0 ? _loadQr : _loadPairing,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'تحديث الرمز',
                    ),
                    Text(
                      _selectedMethodTab == 0 ? 'في انتظار مسح الرمز المربع...' : 'في انتظار إدخال الكود بالهاتف...',
                      style: GoogleFonts.cairo(fontSize: 12, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pollTimer?.cancel();
                Navigator.pop(context);
              },
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                _pollTimer?.cancel();
                String realInstanceName = _instanceName;
                String connectedPhone = _pairingPhoneController.text;

                final user = ref.read(currentUserProvider);
                if (user != null) {
                  try {
                    final clinicRow = await Supabase.instance.client
                        .from('clinics')
                        .select('whatsapp_phone')
                        .eq('id', user.clinicId)
                        .maybeSingle();
                    if (clinicRow != null && clinicRow['whatsapp_phone'] != null) {
                      connectedPhone = clinicRow['whatsapp_phone'] as String;
                    }
                  } catch (_) {}

                  try {
                    final statusRes = await ref.read(whatsappServiceProvider).checkEvolutionStatus(realInstanceName);
                    if (statusRes != null && statusRes['phone'] != null) {
                      String p = statusRes['phone'].toString();
                      if (p.startsWith('201') && p.length == 12) {
                        connectedPhone = '01${p.substring(3)}';
                      } else {
                        connectedPhone = p;
                      }
                    }
                  } catch (_) {}

                  await Supabase.instance.client
                      .from('clinics')
                      .update({
                        'whatsapp_status': 'connected',
                        'whatsapp_enabled': true,
                        'whatsapp_instance_name': realInstanceName,
                        'whatsapp_phone': connectedPhone,
                      })
                      .eq('id', user.clinicId);
                }

                widget.onConnected(connectedPhone, realInstanceName);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 3),
                      content: Text(connectedPhone.isNotEmpty
                          ? 'تم ربط الواتساب بنجاح! رقم العيادة: $connectedPhone'
                          : 'تم ربط حساب الواتساب بنجاح وتفعيل الأتمتة'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: Text('تم المسح والربط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
