import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appointment_model.dart';
import '../domain/service_model.dart';
import '../domain/appointment_service_model.dart';
import '../../auth/domain/user_model.dart';
import '../../../core/demo/demo_clinical_data.dart';

import '../../settings/data/whatsapp_service.dart';

// مزود مستودع المواعيد لجعله متاحاً للاستخدام
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    Supabase.instance.client,
    ref.watch(whatsappServiceProvider),
  );
});

// مزود لجلب الخدمات الإضافية المتاحة بالعيادة (مخزنة في الذاكرة لتنقل فوري)
final availableServicesProvider = FutureProvider.family<List<ServiceModel>, String>((ref, clinicId) async {
  if (clinicId == 'demo-clinic-01') {
    return [
      ServiceModel(id: 's-01', clinicId: clinicId, name: 'سونار حركي للمفصل', price: 150.0),
      ServiceModel(id: 's-02', clinicId: clinicId, name: 'تثبيت جبيرة ودعامة', price: 200.0),
      ServiceModel(id: 's-03', clinicId: clinicId, name: 'غيار جراحي معقم', price: 100.0),
    ];
  }
  return ref.watch(appointmentRepositoryProvider).getAvailableServices(clinicId);
});

// مزود لجلب قائمة الأطباء بالعيادة
final clinicDoctorsProvider = FutureProvider.family<List<UserModel>, String>((ref, clinicId) async {
  if (clinicId == 'demo-clinic-01') {
    return [DemoClinicalData.doctorUser];
  }
  return ref.watch(appointmentRepositoryProvider).getClinicDoctors(clinicId);
});

class AppointmentRepository {
  final SupabaseClient _supabase;
  final WhatsAppService _whatsAppService;

  AppointmentRepository(this._supabase, this._whatsAppService);

  // جلب مواعيد تاريخ محدد لعيادة محددة (clinicId) مرتبة زمنياً تصاعدياً
  Future<List<AppointmentModel>> getAppointmentsByDate(
    String clinicId,
    DateTime date, {
    String? doctorId,
    String? branchId,
  }) async {
    try {
      // بداية اليوم بالـ Local Time وتحويله للتوقيت العالمي الموحد UTC للتوافق مع قاعدة البيانات
      final start = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      // جلب البيانات مع عمل JOIN لبيانات المريض والفرع ونوع الكشف والطبيب والخدمات الإضافية
      var query = _supabase
          .from('appointments')
          .select('*, patients(full_name, phone, address), appointment_types(name), users!doctor_id(full_name), branches!branch_id(name), appointment_services(price_charged, services(name))')
          .eq('clinic_id', clinicId)
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }

      if (branchId != null && branchId.isNotEmpty) {
        query = query.eq('branch_id', branchId);
      }

      final List<dynamic> response = await query.order('appointment_date', ascending: true);

      // تحويل القائمة المستلمة لنماذج AppointmentModel
      return response.map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // إنشاء حجز فوري / كشف مباشر لمريض داخل العيادة
  Future<AppointmentModel> createWalkInAppointment({
    required String clinicId,
    required String patientId,
    String? doctorId,
    String? branchId,
    double price = 0.0,
  }) async {
    try {
      final now = DateTime.now();
      String? defaultTypeId;
      try {
        final types = await _supabase
            .from('appointment_types')
            .select('id, price')
            .eq('clinic_id', clinicId)
            .limit(1);
        if (types.isNotEmpty) {
          defaultTypeId = types.first['id'] as String;
          if (price == 0.0 && types.first['price'] != null) {
            price = (types.first['price'] as num).toDouble();
          }
        }
      } catch (_) {}

      final data = await _supabase.from('appointments').insert({
        'clinic_id': clinicId,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        'patient_id': patientId,
        if (doctorId != null && doctorId.isNotEmpty) 'doctor_id': doctorId,
        if (defaultTypeId != null) 'appointment_type_id': defaultTypeId,
        'appointment_date': now.toUtc().toIso8601String(),
        'price_charged': price,
        'status': 'pending', // مع الطبيب مباشرة
      }).select('*, patients(*), clinics(*)').single();

      return AppointmentModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  // حجز موعد جديد وحفظه في قاعدة البيانات مع الخدمات المرافقة
  Future<void> bookAppointment({
    required String clinicId,
    String? branchId,
    required String patientId,
    String? doctorId,
    required String? appointmentTypeId,
    required DateTime appointmentDate,
    required double priceCharged,
    List<ServiceModel> selectedServices = const [],
  }) async {
    try {
      // 1) فحص التاريخ والوقت القديم
      if (appointmentDate.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
        throw 'اختيار تاريخ أو وقت قديم انتهى';
      }

      // 2) فحص تكرار حجز نفس المريض في نفس اليوم
      final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day).toUtc().toIso8601String();
      final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59).toUtc().toIso8601String();

      var duplicateQuery = _supabase
          .from('appointments')
          .select('id, status')
          .eq('clinic_id', clinicId)
          .eq('patient_id', patientId)
          .gte('appointment_date', startOfDay)
          .lte('appointment_date', endOfDay)
          .neq('status', 'cancelled_by_clinic')
          .neq('status', 'cancelled_by_patient');

      if (doctorId != null && doctorId.isNotEmpty) {
        duplicateQuery = duplicateQuery.eq('doctor_id', doctorId);
      }

      if (branchId != null && branchId.isNotEmpty) {
        duplicateQuery = duplicateQuery.eq('branch_id', branchId);
      }

      final existingAppointments = await duplicateQuery;

      if (existingAppointments.isNotEmpty) {
        throw 'المريض لديه حجز آخر في نفس اليوم';
      }

      final response = await _supabase.from('appointments').insert({
        'clinic_id': clinicId,
        if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
        'patient_id': patientId,
        if (doctorId != null && doctorId.isNotEmpty) 'doctor_id': doctorId,
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

      // إرسال رسالة تأكيد الحجز في الخلفية
      _whatsAppService.sendBookingMessage(
        clinicId: clinicId,
        patientId: patientId,
        appointmentDate: appointmentDate,
        appointmentId: appointmentId,
        doctorId: doctorId,
        branchId: branchId,
      ).catchError((e) {
        debugPrint('Error sending booking confirmation WhatsApp: $e');
      });
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

      if (status == 'cancelled_by_clinic') {
        final appointmentData = await _supabase
            .from('appointments')
            .select('id, clinic_id, patient_id, appointment_date, doctor_id, branch_id')
            .eq('id', appointmentId)
            .maybeSingle();

        if (appointmentData != null) {
          _whatsAppService.sendCancellationMessage(
            clinicId: appointmentData['clinic_id'],
            patientId: appointmentData['patient_id'],
            appointmentDate: DateTime.parse(appointmentData['appointment_date']).toLocal(),
            appointmentId: appointmentData['id'] as String?,
            doctorId: appointmentData['doctor_id'] as String?,
            branchId: appointmentData['branch_id'] as String?,
          ).catchError((e) {
            debugPrint('Error sending cancellation WhatsApp: $e');
          });
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
    if (patientId.startsWith('pat-') || patientId.startsWith('p-') || patientId.startsWith('demo-')) {
      final list = DemoClinicalData.appointments
          .where((app) => app.patientId == patientId)
          .toList();
      if (list.isNotEmpty) return list;
      return [
        AppointmentModel(
          id: 'appt-demo-completed',
          clinicId: 'demo-clinic-01',
          branchId: 'branch-01',
          branchName: 'فرع المعادي الرئيسي',
          patientId: patientId,
          doctorId: 'doc-01',
          doctorName: 'د. عبد الرحمن الزهيري',
          appointmentTypeId: 'type-01',
          appointmentTypeName: 'كشف عظام استشاري دقيق',
          appointmentDate: DateTime.now().subtract(const Duration(days: 7)),
          status: 'completed',
          priceCharged: 350.0,
          totalPaid: 500.0,
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
          serviceNames: ['سونار حركي للمفصل', 'تثبيت دعامة'],
          patient: AppointmentPatient(
            fullName: 'المريض',
            phone: '01234567890',
            address: 'مدينة نصر، القاهرة',
          ),
        ),
      ];
    }
    try {
      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('*, patients(full_name, phone, address), appointment_types(name), users!doctor_id(full_name), branches!branch_id(name), appointment_services(price_charged, services(name))')
          .eq('patient_id', patientId)
          .order('appointment_date', ascending: false);

      return response.map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return DemoClinicalData.appointments
          .where((app) => app.patientId == patientId)
          .toList();
    }
  }

  // جلب جميع الخدمات الإضافية المتاحة بالعيادة
  Future<List<ServiceModel>> getAvailableServices(String clinicId) async {
    if (clinicId == 'demo-clinic-01') {
      return [
        ServiceModel(id: 's-01', clinicId: clinicId, name: 'سونار حركي للمفصل', price: 150.0),
        ServiceModel(id: 's-02', clinicId: clinicId, name: 'تثبيت جبيرة ودعامة', price: 200.0),
        ServiceModel(id: 's-03', clinicId: clinicId, name: 'غيار جراحي معقم', price: 100.0),
      ];
    }
    try {
      final List<dynamic> response = await _supabase
          .from('services')
          .select()
          .eq('clinic_id', clinicId)
          .order('name');

      return response.map((item) => ServiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [
        ServiceModel(id: 's-01', clinicId: clinicId, name: 'سونار حركي للمفصل', price: 150.0),
        ServiceModel(id: 's-02', clinicId: clinicId, name: 'تثبيت جبيرة ودعامة', price: 200.0),
      ];
    }
  }

  // جلب الخدمات المقدمة في موعد معين
  Future<List<AppointmentServiceModel>> getAppointmentServices(String appointmentId) async {
    if (appointmentId.startsWith('appt-') || appointmentId.startsWith('demo-')) {
      return DemoClinicalData.demoServices;
    }
    try {
      final List<dynamic> response = await _supabase
          .from('appointment_services')
          .select('*, services(name)')
          .eq('appointment_id', appointmentId);

      return response.map((item) => AppointmentServiceModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return DemoClinicalData.demoServices;
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

      // إرسال رسائل الإلغاء في الخلفية بطابور الأمان دون تعطيل واجهة العيادة
      for (var app in appointmentsToCancel) {
        _whatsAppService.sendCancellationMessage(
          clinicId: clinicId,
          patientId: app['patient_id'],
          appointmentDate: DateTime.parse(app['appointment_date']).toLocal(),
        ).catchError((e) {
          debugPrint('Error sending bulk cancellation WhatsApp: $e');
        });
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
    String? branchId,
    String? doctorId,
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
            if (branchId != null) 'branch_id': branchId,
            if (doctorId != null) 'doctor_id': doctorId,
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

  // جلب قائمة الأطباء النشطين في العيادة
  Future<List<UserModel>> getClinicDoctors(String clinicId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('users')
          .select()
          .eq('clinic_id', clinicId)
          .eq('role', 'doctor')
          .eq('is_active', true)
          .order('full_name', ascending: true);

      return response.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('getClinicDoctors error: $e');
      return [];
    }
  }
}
