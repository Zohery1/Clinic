import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../main.dart';
import '../../../core/theme/app_theme.dart';

final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService(Supabase.instance.client);
});

class WhatsAppService {
  final SupabaseClient _supabase;
  final String _evoApiKey = "EyadatyEvoSecretKey2026!";
  final String _evoBaseUrl = "http://37.27.31.127:8081";

  WhatsAppService(this._supabase);

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

      await _sendMessageToEvo(
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

      await _sendMessageToEvo(
        instanceName: instanceName,
        phone: phone,
        message: message,
      );
    } catch (e) {
      print('Error sending WhatsApp cancellation message: $e');
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
  }) async {
    // Format the phone number properly
    String formattedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('00')) {
      formattedPhone = formattedPhone.substring(2);
    } else if (formattedPhone.startsWith('01') && formattedPhone.length == 11) {
      formattedPhone = '2$formattedPhone';
    }

    try {
      final response = await _supabase.rpc(
        'send_whatsapp_message_async',
        params: {
          'p_instance_name': instanceName,
          'p_phone': formattedPhone,
          'p_message': message,
          'p_api_key': _evoApiKey,
        },
      );

      final status = response['status'];
      final body = response['body'];
      final error = response['error'];

      if (status != null && status >= 200 && status < 300) {
        print('WhatsApp message sent successfully: $body');
        _showSuccessToast('تم إرسال رسالة واتساب بنجاح');
      } else {
        String err = error?.toString() ?? body?.toString() ?? 'Unknown error';
        if (body != null && body is String) {
          try {
            final decoded = jsonDecode(body);
            final msg = decoded['response']?['message'];
            if (msg is List) {
              err = msg.join(', ');
            } else if (msg != null) {
              err = msg.toString();
            } else if (decoded['error'] != null) {
              err = decoded['error'].toString();
            } else if (decoded['message'] != null) {
              err = decoded['message'].toString();
            }
          } catch (_) {}
        }
        
        print('Failed to send WhatsApp message: $status - $body');
        _showErrorToast('فشل واتساب: $err');
      }
    } catch (e) {
      print('Exception sending WhatsApp message via RPC: $e');
      _showErrorToast('خطأ في الاتصال بسيرفر واتساب (RPC)');
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


