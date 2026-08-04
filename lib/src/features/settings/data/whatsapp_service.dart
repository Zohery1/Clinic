import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        return;
      }

      final instanceName = clinicRes['whatsapp_instance_name'] as String?;
      final template = clinicRes['booking_message_template'] as String?;

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

  Future<void> _sendMessageToEvo({
    required String instanceName,
    required String phone,
    required String message,
  }) async {
    final url = Uri.parse('$_evoBaseUrl/message/sendText/$instanceName');
    
    // Convert local number to international format if starts with 01
    // Usually in Egypt it starts with 01 (e.g. 010, 011) - EVO needs country code
    String formattedPhone = phone;
    if (formattedPhone.startsWith('01') && formattedPhone.length == 11) {
      formattedPhone = '2$formattedPhone';
    }

    final response = await http.post(
      url,
      headers: {
        'apikey': _evoApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "number": formattedPhone,
        "text": message,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('WhatsApp message sent successfully: ${response.body}');
    } else {
      print('Failed to send WhatsApp message: ${response.statusCode} - ${response.body}');
    }
  }
}
