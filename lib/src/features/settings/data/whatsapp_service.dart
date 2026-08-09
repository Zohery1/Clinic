import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../main.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService(Supabase.instance.client);
});

class WhatsAppService {
  final SupabaseClient _supabase;
  static const String _evoApiKey = String.fromEnvironment(
    'EVO_API_KEY',
    defaultValue: "EyadatyEvoSecretKey2026!",
  );

  // ══════════════════════════════════════════════════════════════
  // Anti-Ban Message Queue
  // ══════════════════════════════════════════════════════════════
  // Uses Future-chaining to guarantee messages are sent ONE AT A
  // TIME per instance. Even if 50 cancellations fire at once,
  // they queue up and send sequentially with 5-8s random delays.
  //
  // Per-instance: 5-8s random delay between messages (anti-ban)
  // Global:       2s minimum between ANY messages (CPU protection)  
  // ══════════════════════════════════════════════════════════════
  static final Map<String, Future<void>> _instanceQueue = {};
  static Future<void> _globalQueue = Future.value();
  static final _random = Random();

  /// Minimum delay per instance (anti-ban)
  static const int _minDelaySecondsPerInstance = 5;

  /// Maximum random extra delay (human-like behavior)
  static const int _maxExtraDelaySeconds = 3;

  /// Minimum global delay between ANY message (CPU protection)
  static const int _minGlobalDelaySeconds = 2;

  /// Max retry attempts for wake-up
  static const int _maxRetries = 2;

  String get _evoBaseUrl {
    if (kIsWeb) {
      return "${Uri.base.origin}/api/evo";
    }
    return "http://37.27.31.127:8081";
  }

  WhatsAppService(this._supabase);

  /// Enqueues a message send operation.
  /// 
  /// 1. Per-Instance Queue: Messages for the SAME clinic are sent sequentially
  ///    with a 5-8s random delay (anti-ban protection).
  /// 2. Global Throttle: Messages for DIFFERENT clinics run in parallel,
  ///    but with a short 500ms delay between HTTP requests to protect CPU.
  Future<void> _enqueueMessage({
    required String instanceName,
    required String phone,
    required String message,
  }) async {
    final completer = Completer<void>();

    // 1) Get the previous future for THIS specific clinic
    final previousInstanceFuture = _instanceQueue[instanceName] ?? Future.value();
    _instanceQueue[instanceName] = completer.future;

    // Wait for THIS clinic's previous message to finish
    await previousInstanceFuture.catchError((_) {});

    try {
      // 2) Per-clinic Anti-Ban Delay: 5-8 seconds
      final delayMs = (_minDelaySecondsPerInstance * 1000) +
          _random.nextInt(_maxExtraDelaySeconds * 1000);
      print('[AntiSpam] Instance $instanceName waiting ${delayMs}ms anti-ban delay...');
      await Future.delayed(Duration(milliseconds: delayMs));

      // 3) Global CPU Throttle: Ensure at least 500ms between ANY HTTP request
      final previousGlobal = _globalQueue;
      final globalCompleter = Completer<void>();
      _globalQueue = globalCompleter.future;

      await previousGlobal.catchError((_) {});
      await Future.delayed(const Duration(milliseconds: 500));
      globalCompleter.complete();

      // 4) Send the actual message
      await _sendMessageToEvo(
        instanceName: instanceName,
        phone: phone,
        message: message,
      );
    } finally {
      completer.complete();
    }
  }

  Future<void> sendBookingMessage({
    required String clinicId,
    required String patientId,
    required DateTime appointmentDate,
  }) async {
    try {
      final clinicRes = await _supabase
          .from('clinics')
          .select('whatsapp_enabled, whatsapp_instance_name, send_booking_message, booking_message_template')
          .eq('id', clinicId)
          .maybeSingle();

      if (clinicRes == null || clinicRes['whatsapp_enabled'] != true || clinicRes['send_booking_message'] != true) {
        _showErrorToast('إرسال الواتساب غير مفعل في الإعدادات');
        return;
      }

      final instanceName = clinicRes['whatsapp_instance_name'] as String?;
      final template = clinicRes['booking_message_template'] as String?;

      if (instanceName == null || instanceName.isEmpty) {
        _showErrorToast('اسم الـ Instance غير موجود، يرجى إعادة الربط');
        return;
      }
      if (template == null || template.isEmpty) {
        _showErrorToast('قالب رسالة الحجز فارغ في الإعدادات');
        return;
      }

      final patientRes = await _supabase
          .from('patients')
          .select('full_name, phone')
          .eq('id', patientId)
          .maybeSingle();

      if (patientRes == null || patientRes['phone'] == null || patientRes['phone'].toString().isEmpty) {
        _showErrorToast('المريض ليس لديه رقم هاتف مسجل');
        return;
      }

      final patientName = patientRes['full_name'] as String? ?? 'مريض';
      String phone = patientRes['phone'] as String;

      final dateStr = DateFormat('yyyy-MM-dd').format(appointmentDate);
      final timeStr = DateFormat('hh:mm a').format(appointmentDate);

      String message = template
          .replaceAll('[patient_name]', patientName)
          .replaceAll('[date]', dateStr)
          .replaceAll('[time]', timeStr);

      await _enqueueMessage(
        instanceName: instanceName,
        phone: phone,
        message: message,
      );
    } catch (e) {
      _showErrorToast('حدث خطأ داخلي أثناء تجهيز الرسالة: $e');
      print('Error sending WhatsApp booking message: $e');
    }
  }

  Future<void> sendCancellationMessage({
    required String clinicId,
    required String patientId,
    required DateTime appointmentDate,
  }) async {
    try {
      // عدم إرسال رسالة الاعتذار/الإلغاء إذا كان تاريخ ووقت الموعد قد مضى بالفعل
      if (appointmentDate.toUtc().isBefore(DateTime.now().toUtc())) {
        print('[WhatsApp] ⏭️ تجاوز إرسال رسالة الاعتذار لأن وقت الموعد قد مضى بالفعل ($appointmentDate)');
        return;
      }

      final clinicRes = await _supabase
          .from('clinics')
          .select('whatsapp_enabled, whatsapp_instance_name, send_cancellation_message, cancellation_message_template')
          .eq('id', clinicId)
          .maybeSingle();

      if (clinicRes == null || clinicRes['whatsapp_enabled'] != true || clinicRes['send_cancellation_message'] != true) {
        return;
      }

      final instanceName = clinicRes['whatsapp_instance_name'] as String?;
      final template = clinicRes['cancellation_message_template'] as String?;

      if (instanceName == null || instanceName.isEmpty || template == null || template.isEmpty) {
        return;
      }

      final patientRes = await _supabase
          .from('patients')
          .select('full_name, phone')
          .eq('id', patientId)
          .maybeSingle();

      if (patientRes == null || patientRes['phone'] == null || patientRes['phone'].toString().isEmpty) {
        return;
      }

      final patientName = patientRes['full_name'] as String? ?? 'مريض';
      String phone = patientRes['phone'] as String;

      final dateStr = DateFormat('yyyy-MM-dd').format(appointmentDate);
      final timeStr = DateFormat('hh:mm a').format(appointmentDate);

      String message = template
          .replaceAll('[patient_name]', patientName)
          .replaceAll('[date]', dateStr)
          .replaceAll('[time]', timeStr);

      await _enqueueMessage(
        instanceName: instanceName,
        phone: phone,
        message: message,
      );
    } catch (e) {
      print('Error sending WhatsApp cancellation message: $e');
    }
  }

  /// إرسال رسالة واتساب مخصصة لأي مريض عبر الخدمة
  Future<bool> sendCustomMessage({
    required String clinicId,
    required String phone,
    required String message,
  }) async {
    try {
      final clinicRes = await _supabase
          .from('clinics')
          .select('whatsapp_enabled, whatsapp_instance_name')
          .eq('id', clinicId)
          .maybeSingle();

      if (clinicRes == null || clinicRes['whatsapp_enabled'] != true) {
        return false;
      }

      final instanceName = clinicRes['whatsapp_instance_name'] as String?;
      if (instanceName == null || instanceName.isEmpty) {
        return false;
      }

      await _enqueueMessage(
        instanceName: instanceName,
        phone: phone,
        message: message,
      );
      return true;
    } catch (e) {
      print('Error sending custom WhatsApp message: $e');
      return false;
    }
  }

  void _showErrorToast(String message) {
    final state = rootScaffoldMessengerKey.currentState;
    if (state == null) return;
    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        backgroundColor: AppTheme.error,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessToast(String message) {
    final state = rootScaffoldMessengerKey.currentState;
    if (state == null) return;
    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        backgroundColor: AppTheme.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessageToEvo({
    required String instanceName,
    required String phone,
    required String message,
    int retryCount = 0,
  }) async {
    // Format the phone number properly
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('00')) {
      formattedPhone = formattedPhone.substring(2);
    } else if (formattedPhone.startsWith('01') && formattedPhone.length == 11) {
      formattedPhone = '2$formattedPhone';
    }

    try {
      final url = Uri.parse('$_evoBaseUrl/message/sendText/$instanceName');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _evoApiKey,
        },
        body: jsonEncode({
          'number': formattedPhone,
          'text': message,
        }),
      );

      final status = response.statusCode;
      final body = response.body;

      if (status >= 200 && status < 300) {
        AppLogger.info('[WhatsApp] ✅ Message sent to ${AppLogger.maskPhone(formattedPhone)} via $instanceName');
        _showSuccessToast('تم إرسال رسالة واتساب بنجاح');
      } else {
        String err = body;
        try {
          final decoded = jsonDecode(body);
          final msg = decoded['response']?['message'] ?? decoded['error'] ?? decoded['message'];
          if (msg is List) {
            err = msg.join(', ');
          } else if (msg != null) {
            err = msg.toString();
          }
        } catch (_) {}

        final errLower = err.toLowerCase();
        final isConnectionClosed = errLower.contains('connection closed') ||
            errLower.contains('not connected') ||
            errLower.contains('disconnected');

        if (isConnectionClosed && retryCount < _maxRetries) {
          print('[WhatsApp] ⚡ Session closed for $instanceName. Auto-wakeup attempt ${retryCount + 1}/$_maxRetries...');
          try {
            await http.get(
              Uri.parse('$_evoBaseUrl/instance/connect/$instanceName'),
              headers: {'apikey': _evoApiKey},
            ).timeout(const Duration(seconds: 5));
          } catch (e) {
            print('[WhatsApp] ⚠️ Error waking up instance: $e');
          }

          // Wait 5 seconds for session to restore from Redis-saved credentials
          await Future.delayed(const Duration(seconds: 5));

          // Retry sending message
          return _sendMessageToEvo(
            instanceName: instanceName,
            phone: phone,
            message: message,
            retryCount: retryCount + 1,
          );
        }

        String userFriendlyError = 'فشل واتساب: $err';
        if (isConnectionClosed) {
          userFriendlyError = 'واتساب غير متصل بالموبيل، يرجى فتح الإعدادات ومسح الـ QR Code لربط الرقم';
        } else if (errLower.contains('not found') || errLower.contains('does not exist')) {
          userFriendlyError = 'جلسة الواتساب غير موجودة، يرجى إعادة الربط من الإعدادات';
        }

        print('[WhatsApp] ❌ Failed: $status - $body');
        _showErrorToast(userFriendlyError);
      }
    } catch (e) {
      print('[WhatsApp] ❌ Exception: $e');
      _showErrorToast('خطأ في الاتصال بسيرفر واتساب');
    }
  }

  Future<Map<String, dynamic>?> fetchEvolutionQr(String instanceName) async {
    try {
      final connectUrl = Uri.parse('$_evoBaseUrl/instance/connect/$instanceName');
      final res = await http.get(
        connectUrl,
        headers: {'apikey': _evoApiKey},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      }

      final createUrl = Uri.parse('$_evoBaseUrl/instance/create');
      final createRes = await http.post(
        createUrl,
        headers: {
          'apikey': _evoApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instanceName': instanceName,
          'qrcode': true,
          'integration': 'WHATSAPP-BAILEYS',
        }),
      ).timeout(const Duration(seconds: 15));

      if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
        final data = jsonDecode(createRes.body);
        if (data is Map<String, dynamic>) {
          if (data['qrcode'] != null && data['qrcode'] is Map) {
            return data['qrcode'] as Map<String, dynamic>;
          }
          return data;
        }
      }
    } catch (e) {
      print('Error fetching QR directly from Evolution API: $e');
    }
    return null;
  }

  Future<void> deleteInstance(String instanceName) async {
    try {
      await http.delete(
        Uri.parse('$_evoBaseUrl/instance/delete/$instanceName'),
        headers: {'apikey': _evoApiKey},
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      print('[WhatsApp] Reset instance warning: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchEvolutionPairingCode({
    required String instanceName,
    required String phone,
  }) async {
    try {
      String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.startsWith('01') && cleanPhone.length == 11) {
        cleanPhone = '20$cleanPhone';
      } else if (cleanPhone.startsWith('00')) {
        cleanPhone = cleanPhone.substring(2);
      }

      if (cleanPhone.isEmpty) {
        return {'error': 'يرجى إدخال رقم الهاتف المربوط بالواتساب'};
      }

      String? extractCode(dynamic data) {
        if (data is Map<String, dynamic>) {
          String? candidate = data['pairingCode']?.toString() ??
              data['pairing_code']?.toString() ??
              data['code']?.toString() ??
              data['qrcode']?['pairingCode']?.toString();

          if (candidate != null && candidate.trim().length <= 12 && !candidate.contains('/') && !candidate.contains('=')) {
            return candidate.trim();
          }
        }
        return null;
      }

      // 1) Clean reset any existing instance socket (e.g. QR session) to prevent Baileys socket mode conflict
      await deleteInstance(instanceName);

      // 2) Create fresh instance in pairing mode (qrcode: false) with phone number
      final createUrl = Uri.parse('$_evoBaseUrl/instance/create');
      print('[WhatsApp] 🔑 Creating fresh pairing instance for $instanceName ($cleanPhone)...');
      final createRes = await http.post(
        createUrl,
        headers: {
          'apikey': _evoApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instanceName': instanceName,
          'qrcode': false,
          'number': cleanPhone,
          'integration': 'WHATSAPP-BAILEYS',
        }),
      ).timeout(const Duration(seconds: 15));

      if (createRes.statusCode >= 200 && createRes.statusCode < 300) {
        final data = jsonDecode(createRes.body);
        final code = extractCode(data);
        if (code != null) {
          return {'pairingCode': code};
        }
      }

      // 3) Request pairing code via connect endpoint
      final pairingUrl = Uri.parse('$_evoBaseUrl/instance/connect/pairing-code/$instanceName?number=$cleanPhone');
      final res = await http.get(
        pairingUrl,
        headers: {'apikey': _evoApiKey},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final code = extractCode(data);
        if (code != null) {
          return {'pairingCode': code};
        }
      }

      final connectUrl = Uri.parse('$_evoBaseUrl/instance/connect/$instanceName?number=$cleanPhone');
      final resConnect = await http.get(
        connectUrl,
        headers: {'apikey': _evoApiKey},
      ).timeout(const Duration(seconds: 12));

      if (resConnect.statusCode >= 200 && resConnect.statusCode < 300) {
        final data = jsonDecode(resConnect.body);
        final code = extractCode(data);
        if (code != null) {
          return {'pairingCode': code};
        }
      }
    } catch (e) {
      print('Error fetching pairing code from Evolution API: $e');
      return {'error': 'خطأ في الاتصال بسيرفر واتساب: $e'};
    }
    return {'error': 'لم يتم تلقي كود الاقتران. تأكد من صحة رقم الهاتف'};
  }

  Future<Map<String, dynamic>?> checkEvolutionStatus(String instanceName) async {
    try {
      final url = Uri.parse('$_evoBaseUrl/instance/connectionState/$instanceName');
      final res = await http.get(
        url,
        headers: {'apikey': _evoApiKey},
      ).timeout(const Duration(seconds: 7));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final state = data['instance']?['state'] ?? data['state'];
        if (state == 'open') {
          return {
            'connectionStatus': 'open',
            'phone': data['instance']?['owner'] ?? data['owner'] ?? '',
          };
        }
        return {'connectionStatus': state};
      }
    } catch (e) {
      print('Error checking connection state: $e');
    }
    return null;
  }
}


