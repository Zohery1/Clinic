import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../appointments/domain/appointment_type_model.dart';
import '../../appointments/domain/service_model.dart';

// مزود مستودع التقارير والأسعار لجعله متاحاً للاستخدام
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(Supabase.instance.client);
});

class ReportsRepository {
  final SupabaseClient _supabase;

  ReportsRepository(this._supabase);

  // ==========================================
  // إدارة قائمة أسعار المواعيد (Appointment Types)
  // ==========================================

  Future<List<AppointmentTypeModel>> getAppointmentTypes(String clinicId) async {
    final response = await _supabase
        .from('appointment_types')
        .select()
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => AppointmentTypeModel.fromJson(json)).toList();
  }

  Future<AppointmentTypeModel> addAppointmentType({
    required String clinicId,
    required String name,
    required double price,
  }) async {
    final response = await _supabase
        .from('appointment_types')
        .insert({
          'clinic_id': clinicId,
          'name': name,
          'price': price,
        })
        .select()
        .single();
    return AppointmentTypeModel.fromJson(response);
  }

  Future<void> deleteAppointmentType(String id) async {
    await _supabase.from('appointment_types').delete().eq('id', id);
  }

  Future<AppointmentTypeModel> updateAppointmentType({
    required String id,
    required String name,
    required double price,
  }) async {
    final response = await _supabase
        .from('appointment_types')
        .update({
          'name': name,
          'price': price,
        })
        .eq('id', id)
        .select()
        .single();
    return AppointmentTypeModel.fromJson(response);
  }

  // ==========================================
  // إدارة قائمة الخدمات الإضافية (Services)
  // ==========================================

  Future<List<ServiceModel>> getServices(String clinicId) async {
    final response = await _supabase
        .from('services')
        .select()
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => ServiceModel.fromJson(json)).toList();
  }

  Future<ServiceModel> addService({
    required String clinicId,
    required String name,
    required double price,
  }) async {
    final response = await _supabase
        .from('services')
        .insert({
          'clinic_id': clinicId,
          'name': name,
          'price': price,
        })
        .select()
        .single();
    return ServiceModel.fromJson(response);
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }

  Future<ServiceModel> updateService({
    required String id,
    required String name,
    required double price,
  }) async {
    final response = await _supabase
        .from('services')
        .update({
          'name': name,
          'price': price,
        })
        .eq('id', id)
        .select()
        .single();
    return ServiceModel.fromJson(response);
  }

  // ==========================================
  // استعلامات التقارير المالية (Financial Reports)
  // ==========================================

  // جلب دخل اليوم المختار للعيادة المسجلة
  Future<double> getTodayRevenue(String clinicId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
      final end = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();

      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('price_charged, appointment_services(price_charged)')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      double total = 0.0;
      for (var row in response) {
        total += (row['price_charged'] as num? ?? 0.0).toDouble();
        final services = row['appointment_services'] as List<dynamic>?;
        if (services != null) {
          for (var s in services) {
            total += (s['price_charged'] as num? ?? 0.0).toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // جلب دخل الشهر للعيادة المسجلة
  Future<double> getMonthRevenue(String clinicId) async {
    try {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, 1).toUtc().toIso8601String();
      final lastDay = DateTime(today.year, today.month + 1, 0, 23, 59, 59);
      final end = lastDay.toUtc().toIso8601String();

      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('price_charged, appointment_services(price_charged)')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      double total = 0.0;
      for (var row in response) {
        total += (row['price_charged'] as num? ?? 0.0).toDouble();
        final services = row['appointment_services'] as List<dynamic>?;
        if (services != null) {
          for (var s in services) {
            total += (s['price_charged'] as num? ?? 0.0).toDouble();
          }
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // جلب دخل آخر 7 أيام لعرضه في الرسم البياني
  Future<List<Map<String, dynamic>>> getWeeklyRevenue(String clinicId) async {
    try {
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 6));
      final start = DateTime(weekAgo.year, weekAgo.month, weekAgo.day).toUtc().toIso8601String();
      final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toUtc().toIso8601String();

      final List<dynamic> response = await _supabase
          .from('appointments')
          .select('appointment_date, price_charged, appointment_services(price_charged)')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      final Map<String, double> revenueMap = {};
      for (int i = 0; i < 7; i++) {
        final day = weekAgo.add(Duration(days: i));
        final dayStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        revenueMap[dayStr] = 0.0;
      }

      for (var row in response) {
        final dateLocal = DateTime.parse(row['appointment_date'] as String).toLocal();
        final dayStr = "${dateLocal.year}-${dateLocal.month.toString().padLeft(2, '0')}-${dateLocal.day.toString().padLeft(2, '0')}";
        
        if (revenueMap.containsKey(dayStr)) {
          double appTotal = (row['price_charged'] as num? ?? 0.0).toDouble();
          final services = row['appointment_services'] as List<dynamic>?;
          if (services != null) {
            for (var s in services) {
              appTotal += (s['price_charged'] as num? ?? 0.0).toDouble();
            }
          }
          revenueMap[dayStr] = revenueMap[dayStr]! + appTotal;
        }
      }

      return revenueMap.entries.map((e) => {
        'date': e.key,
        'revenue': e.value,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // جلب إحصائيات الأيام التفصيلية
  Future<List<Map<String, dynamic>>> getDailyStats({
    required String clinicId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final start = DateTime.parse(startDate).toUtc().toIso8601String();
      final endParsed = DateTime.parse(endDate);
      final end = DateTime(endParsed.year, endParsed.month, endParsed.day, 23, 59, 59).toUtc().toIso8601String();

      final List<dynamic> appointments = await _supabase
          .from('appointments')
          .select('appointment_date, price_charged, appointment_services(price_charged)')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      final Map<String, double> revenues = {};
      final Map<String, int> visits = {};

      for (var app in appointments) {
        final dateLocal = DateTime.parse(app['appointment_date'] as String).toLocal();
        final dayStr = "${dateLocal.year}-${dateLocal.month.toString().padLeft(2, '0')}-${dateLocal.day.toString().padLeft(2, '0')}";

        double appTotal = (app['price_charged'] as num? ?? 0.0).toDouble();
        final services = app['appointment_services'] as List<dynamic>?;
        if (services != null) {
          for (var s in services) {
            appTotal += (s['price_charged'] as num? ?? 0.0).toDouble();
          }
        }
        revenues[dayStr] = (revenues[dayStr] ?? 0.0) + appTotal;
        visits[dayStr] = (visits[dayStr] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> results = [];
      final Set<String> allDays = {...revenues.keys, ...visits.keys};
      
      for (var dayStr in allDays) {
        final rev = revenues[dayStr] ?? 0.0;
        final vis = visits[dayStr] ?? 0;
        if (rev > 0 || vis > 0) {
          results.add({
            'date': dayStr,
            'revenue': rev,
            'visits': vis,
          });
        }
      }

      results.sort((a, b) => b['date'].compareTo(a['date']));
      if (results.length > 15) {
        return results.sublist(0, 15);
      }
      return results;
    } catch (e, s) {
      print('getDailyStats ERROR: $e');
      print('Stacktrace: $s');
      rethrow;
    }
  }

  // جلب إحصائيات الشهور التراكمية
  Future<List<Map<String, dynamic>>> getMonthlyStats(String clinicId) async {
    try {
      final today = DateTime.now();
      final oneYearAgo = DateTime(today.year - 1, today.month, 1).toUtc().toIso8601String();

      final List<dynamic> appointments = await _supabase
          .from('appointments')
          .select('appointment_date, price_charged, appointment_services(price_charged)')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', oneYearAgo);

      final Map<String, double> revenues = {};
      final Map<String, int> visits = {};

      for (var app in appointments) {
        final dateLocal = DateTime.parse(app['appointment_date'] as String).toLocal();
        final monthStr = "${dateLocal.year}-${dateLocal.month.toString().padLeft(2, '0')}";

        double appTotal = (app['price_charged'] as num? ?? 0.0).toDouble();
        final services = app['appointment_services'] as List<dynamic>?;
        if (services != null) {
          for (var s in services) {
            appTotal += (s['price_charged'] as num? ?? 0.0).toDouble();
          }
        }
        revenues[monthStr] = (revenues[monthStr] ?? 0.0) + appTotal;
        visits[monthStr] = (visits[monthStr] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> results = [];
      final Set<String> allMonths = {...revenues.keys, ...visits.keys};
      
      for (var monthStr in allMonths) {
        final rev = revenues[monthStr] ?? 0.0;
        final vis = visits[monthStr] ?? 0;
        if (rev > 0 || vis > 0) {
          results.add({
            'month': monthStr,
            'revenue': rev,
            'visits': vis,
          });
        }
      }

      results.sort((a, b) => b['month'].compareTo(a['month']));
      if (results.length > 15) {
        return results.sublist(0, 15);
      }
      return results;
    } catch (e, s) {
      print('getMonthlyStats ERROR: $e');
      print('Stacktrace: $s');
      rethrow;
    }
  }

  // ==========================================
  // جلب تقرير تفصيلي ليوم أو فترة زمنية
  // ==========================================
  Future<Map<String, dynamic>> getDetailedReport({
    required String clinicId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final start = DateTime.parse(startDate).toUtc().toIso8601String();
      final endParsed = DateTime.parse(endDate);
      final end = DateTime(endParsed.year, endParsed.month, endParsed.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      // جلب المواعيد المكتملة مع بياناتها الكاملة
      final List<dynamic> appointments = await _supabase
          .from('appointments')
          .select('''
            id,
            patient_id,
            price_charged,
            appointment_types(name),
            appointment_services(
              price_charged,
              services(name)
            )
          ''')
          .eq('clinic_id', clinicId)
          .eq('status', 'completed')
          .gte('appointment_date', start)
          .lte('appointment_date', end);

      // تجميع الكشوفات حسب النوع
      final Map<String, Map<String, dynamic>> appointmentsByType = {};
      double totalAppointmentsRevenue = 0.0;
      double totalServicesRevenue = 0.0;
      final Set<String> patientIds = {};

      for (var app in appointments) {
        patientIds.add(app['patient_id'] as String);

        final typeJson = app['appointment_types'] as Map<String, dynamic>?;
        final typeName = typeJson?['name'] as String? ?? 'كشف غير محدد';
        final basePrice = (app['price_charged'] as num? ?? 0.0).toDouble();

        appointmentsByType.putIfAbsent(typeName, () => {'name': typeName, 'count': 0, 'totalCost': 0.0});
        appointmentsByType[typeName]!['count'] = (appointmentsByType[typeName]!['count'] as int) + 1;
        appointmentsByType[typeName]!['totalCost'] =
            (appointmentsByType[typeName]!['totalCost'] as double) + basePrice;
        totalAppointmentsRevenue += basePrice;

        // تحسيب إجمالي الخدمات فقط (التجميع التفصيلي في اللوب التاني)
        final servicesList = app['appointment_services'] as List<dynamic>? ?? [];
        for (var svc in servicesList) {
          final svcMap = svc as Map<String, dynamic>;
          final svcPrice = (svcMap['price_charged'] as num? ?? 0.0).toDouble();
          totalServicesRevenue += svcPrice;
        }
      }

      // --- تجميع الخدمات داخل الـ loop بشكل صحيح ---
      // (نعيد الحساب لتجنب مشكلة المتغير المؤقت)
      final Map<String, Map<String, dynamic>> servicesByType = {};
      for (var app in appointments) {
        final servicesList = app['appointment_services'] as List<dynamic>? ?? [];
        for (var svc in servicesList) {
          final svcMap = svc as Map<String, dynamic>;
          final svcName =
              (svcMap['services'] as Map<String, dynamic>?)?['name'] as String? ?? 'خدمة غير محددة';
          final svcPrice = (svcMap['price_charged'] as num? ?? 0.0).toDouble();
          servicesByType.putIfAbsent(svcName, () => {'name': svcName, 'count': 0, 'totalCost': 0.0});
          servicesByType[svcName]!['count'] = (servicesByType[svcName]!['count'] as int) + 1;
          servicesByType[svcName]!['totalCost'] =
              (servicesByType[svcName]!['totalCost'] as double) + svcPrice;
        }
      }

      // جلب المرضى الجدد (created_at في نفس الفترة الزمنية)
      final List<dynamic> newPatientsResponse = await _supabase
          .from('patients')
          .select('id')
          .eq('clinic_id', clinicId)
          .gte('created_at', start)
          .lte('created_at', end);

      final int newPatientsCount = newPatientsResponse.length;

      // المرضى القدامى = زوار الفترة - الجدد منهم
      final newPatientIds =
          (newPatientsResponse).map((p) => p['id'] as String).toSet();
      final int oldPatientsCount =
          patientIds.where((id) => !newPatientIds.contains(id)).length;

      return {
        'appointmentsByType': appointmentsByType.values.toList(),
        'servicesByType': servicesByType.values.toList(),
        'totalAppointmentsRevenue': totalAppointmentsRevenue,
        'totalServicesRevenue': totalServicesRevenue,
        'totalRevenue': totalAppointmentsRevenue + totalServicesRevenue,
        'totalVisits': appointments.length,
        'newPatientsCount': newPatientsCount,
        'oldPatientsCount': oldPatientsCount,
      };
    } catch (e, s) {
      print('getDetailedReport ERROR: $e');
      print('Stacktrace: $s');
      rethrow;
    }
  }

}

