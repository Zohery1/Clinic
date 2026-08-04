import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appointment_model.dart';
import '../domain/service_model.dart';
import '../domain/appointment_service_model.dart';

import '../../settings/data/whatsapp_service.dart';

// مزود مستودع المواعيد لجعله متاحاً للاستخدام
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    Supabase.instance.client,
    ref.watch(whatsappServiceProvider),
  );
});

// مزود لجلب الخدمات الإضافية المتاحة بالعيادة
final availableServicesProvider = FutureProvider.family.autoDispose<List<ServiceModel>, String>((ref, clinicId) async {
  return ref.watch(appointmentRepositoryProvider).getAvailableServices(clinicId);
});

class AppointmentRepository {
  final SupabaseClient _supabase;
  final WhatsAppService _whatsAppService;

  AppointmentRepository(this._supabase, this._whatsAppService);

  // جلب مواعيد تاريخ محدد لعيادة محددة (clinicId) مرتبة زمنياً تصاعدياً
  Future<List<AppointmentModel>> getAppointmentsByDate(String clinicId, DateTime date) async {
    try {
      // بداية اليوم بالـ Local Time وتحويله للتوقيت العالمي الموحد UTC للتوافق مع قاعدة البيانات
      final start = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      // جلب البيانات مع عمل JOIN لبيانات المريض (الاسم والهاتف والعنوان) ونوع الكشف والخدمات الإضافية
      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('*, patients(full_name, phone, address), appointment_types(name), appointment_services(price_charged, services(name))')
          .eq('clinic_id', clinicId)
          .gte('appointment_date', start)
          .lte('appointment_date', end)
          .order('appointment_date', ascending: true);

      // تحويل القائمة المستلمة لنماذج AppointmentModel
      return response.map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // حجز موعد جديد وحفظه في قاعدة البيانات مع الخدمات المرافقة
  Future<void> bookAppointment({
    required String clinicId,
    required String patientId,
    required String? appointmentTypeId,
    required DateTime appointmentDate,
    required double priceCharged,
    List<ServiceModel> selectedServices = const [],
  }) async {
    try {
      final response = await _supabase.from('appointments').insert({
        'clinic_id': clinicId,
        'patient_id': patientId,
        'appointment_type_id': appointmentTypeId,
        'appointment_date': appointmentDate.toUtc().toIso8601String(),
        'price_charged': priceCharged,
        'status': 'confirmed', // تأكيد تلقائي عند إدخاله من قبل العيادة
      }).select().single();

      final String appointmentId = response['id'] as String;

      if (selectedServices.isNotEmpty) {
        final servicesData = selectedServices.map((service) => {
          'clinic_id': clinicId,
          'appointment_id': appointmentId,
          'service_id': service.id,
          'price_charged': service.price,
        }).toList();

        await _supabase.from('appointment_services').insert(servicesData);
      }

      // إرسال رسالة واتساب
      await _whatsAppService.sendBookingMessage(
        clinicId: clinicId,
        patientId: patientId,
        appointmentDate: appointmentDate,
      );
    } catch (e) {
      rethrow;
    }
  }

  // تحديث حالة الحجز (مؤكد، ملغي، مكتمل)
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);

      if (status == 'cancelled_by_clinic' || status == 'cancelled_by_patient') {
        final appointmentData = await _supabase
            .from('appointments')
            .select('clinic_id, patient_id, appointment_date')
            .eq('id', appointmentId)
            .maybeSingle();

        if (appointmentData != null) {
          await _whatsAppService.sendCancellationMessage(
            clinicId: appointmentData['clinic_id'],
            patientId: appointmentData['patient_id'],
            appointmentDate: DateTime.parse(appointmentData['appointment_date']).toLocal(),
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // تحديث الخدمات المرافقة لحجز معين
  Future<void> updateAppointmentServices({
    required String clinicId,
    required String appointmentId,
    required List<ServiceModel> selectedServices,
  }) async {
    try {
      // حذف الخدمات السابقة أولاً
      await _supabase
          .from('appointment_services')
          .delete()
          .eq('appointment_id', appointmentId);

      // إضافة الخدمات الجديدة إن وجدت
      if (selectedServices.isNotEmpty) {
        final servicesData = selectedServices.map((service) => {
          'clinic_id': clinicId,
          'appointment_id': appointmentId,
          'service_id': service.id,
          'price_charged': service.price,
        }).toList();

        await _supabase.from('appointment_services').insert(servicesData);
      }
    } catch (e) {
      rethrow;
    }
  }

  // جلب جميع مواعيد مريض محدد مرتبة بالأحدث أولاً
  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('*, patients(full_name, phone, address), appointment_types(name), appointment_services(price_charged, services(name))')
          .eq('patient_id', patientId)
          .order('appointment_date', ascending: false);

      return response.map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // جلب جميع الخدمات الإضافية المتاحة بالعيادة
  Future<List<ServiceModel>> getAvailableServices(String clinicId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('services')
          .select()
          .eq('clinic_id', clinicId)
          .order('name');

      return response.map((item) => ServiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // جلب الخدمات المقدمة في موعد معين
  Future<List<AppointmentServiceModel>> getAppointmentServices(String appointmentId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('appointment_services')
          .select('*, services(name)')
          .eq('appointment_id', appointmentId);

      return response.map((item) => AppointmentServiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // إلغاء جميع مواعيد يوم محدد التي بحالة confirmed (في الانتظار) فقط
  Future<void> cancelAllTodayAppointments(String clinicId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      // جلب المواعيد التي سيتم إلغاؤها لإرسال الواتساب
      final appointmentsToCancel = await _supabase
          .from('appointments')
          .select('id, patient_id, appointment_date')
          .eq('clinic_id', clinicId)
          .eq('status', 'confirmed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      await _supabase
          .from('appointments')
          .update({'status': 'cancelled_by_clinic'})
          .eq('clinic_id', clinicId)
          .eq('status', 'confirmed') // فقط اللي في الانتظار، لا يمس المبدوءة
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      // إرسال رسائل الإلغاء
      for (var app in appointmentsToCancel) {
        await _whatsAppService.sendCancellationMessage(
          clinicId: clinicId,
          patientId: app['patient_id'],
          appointmentDate: DateTime.parse(app['appointment_date']).toLocal(),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // إنهاء الكشف بشكل ذري: حفظ الخدمات + تغيير الحالة إلى completed دفعة واحدة
  Future<void> completeExamination({
    required String clinicId,
    required String appointmentId,
    required List<ServiceModel> selectedServices,
  }) async {
    try {
      // تحديث الخدمات أولاً
      await _supabase
          .from('appointment_services')
          .delete()
          .eq('appointment_id', appointmentId);

      if (selectedServices.isNotEmpty) {
        final servicesData = selectedServices.map((service) => {
          'clinic_id': clinicId,
          'appointment_id': appointmentId,
          'service_id': service.id,
          'price_charged': service.price,
        }).toList();
        await _supabase.from('appointment_services').insert(servicesData);
      }

      // تغيير الحالة إلى completed
      await _supabase
          .from('appointments')
          .update({'status': 'completed'})
          .eq('id', appointmentId);
    } catch (e) {
      rethrow;
    }
  }

  // تحديث بيانات حجز موجود
  Future<void> updateAppointment({
    required String clinicId,
    required String appointmentId,
    required String patientId,
    required String? appointmentTypeId,
    required DateTime appointmentDate,
    required double priceCharged,
    required List<ServiceModel> selectedServices,
  }) async {
    try {
      // تحديث البيانات الأساسية
      await _supabase
          .from('appointments')
          .update({
            'patient_id': patientId,
            'appointment_type_id': appointmentTypeId,
            'appointment_date': appointmentDate.toUtc().toIso8601String(),
            'price_charged': priceCharged,
          })
          .eq('id', appointmentId);

      // تحديث الخدمات المرافقة
      await updateAppointmentServices(
        clinicId: clinicId,
        appointmentId: appointmentId,
        selectedServices: selectedServices,
      );
    } catch (e) {
      rethrow;
    }
  }
}
