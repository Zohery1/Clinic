import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/login_controller.dart';
import '../../appointments/presentation/appointments_controller.dart';
import '../data/reports_repository.dart';
import '../../appointments/domain/appointment_type_model.dart';
import '../../appointments/domain/service_model.dart';

// مزود لقائمة أنواع المواعيد
final appointmentTypesProvider = FutureProvider<List<AppointmentTypeModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reportsRepositoryProvider).getAppointmentTypes(user.clinicId);
});

// مزود لقائمة الخدمات الإضافية
final servicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reportsRepositoryProvider).getServices(user.clinicId);
});

// مزود دخل اليوم المختار
final todayRevenueProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(reportsRepositoryProvider).getTodayRevenue(user.clinicId, selectedDate);
});

// مزود دخل الشهر الحالي
final monthRevenueProvider = FutureProvider<double>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  return ref.watch(reportsRepositoryProvider).getMonthRevenue(user.clinicId);
});

// مزود دخل آخر 7 أيام للرسم البياني
final weeklyRevenueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reportsRepositoryProvider).getWeeklyRevenue(user.clinicId);
});

// مزود دخل آخر 6 أسابيع للرسم البياني الأسبوعي
final sixWeeksRevenueProvider = FutureProvider<List<double>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final today = DateTime.now();
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final fortyOneDaysAgo = todayMidnight.subtract(const Duration(days: 41));

  final startStr = "${fortyOneDaysAgo.year}-${fortyOneDaysAgo.month.toString().padLeft(2, '0')}-${fortyOneDaysAgo.day.toString().padLeft(2, '0')}";
  final endStr = "${todayMidnight.year}-${todayMidnight.month.toString().padLeft(2, '0')}-${todayMidnight.day.toString().padLeft(2, '0')}";

  final dailyData = await ref.read(reportsRepositoryProvider).getDailyStats(
        clinicId: user.clinicId,
        startDate: startStr,
        endDate: endStr,
      );

  final List<double> weeklyRevenues = List.filled(6, 0.0);

  for (final dayData in dailyData) {
    final dateStr = dayData['date'] as String;
    final date = DateTime.tryParse(dateStr);
    if (date == null) continue;

    final dateMidnight = DateTime(date.year, date.month, date.day);
    final diffDays = todayMidnight.difference(dateMidnight).inDays;
    if (diffDays >= 0 && diffDays < 42) {
      final weekIdx = diffDays ~/ 7;
      if (weekIdx >= 0 && weekIdx < 6) {
        weeklyRevenues[weekIdx] += (dayData['revenue'] as num? ?? 0.0).toDouble();
      }
    }
  }

  return weeklyRevenues;
});

// مزود إحصائيات الأيام التفصيلية (Family Provider)
final dailyStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, rangeStr) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final parts = rangeStr.split('_');
  final startDate = parts[0];
  final endDate = parts[1];
  return ref.watch(reportsRepositoryProvider).getDailyStats(
        clinicId: user.clinicId,
        startDate: startDate,
        endDate: endDate,
      );
});

// مزود إحصائيات الشهور التراكمية
final monthlyStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(reportsRepositoryProvider).getMonthlyStats(user.clinicId);
});

// مزود التقرير التفصيلي لفترة زمنية محددة (يوم أو شهر)
// المفتاح: "startDate_endDate" (مثال: "2025-01-15_2025-01-15")
final detailedReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, rangeStr) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return {
      'appointmentsByType': <Map<String, dynamic>>[],
      'servicesByType': <Map<String, dynamic>>[],
      'totalAppointmentsRevenue': 0.0,
      'totalServicesRevenue': 0.0,
      'totalRevenue': 0.0,
      'totalVisits': 0,
      'newPatientsCount': 0,
      'oldPatientsCount': 0,
    };
  }
  final parts = rangeStr.split('_');
  final startDate = parts[0];
  final endDate = parts[1];
  return ref.watch(reportsRepositoryProvider).getDetailedReport(
        clinicId: user.clinicId,
        startDate: startDate,
        endDate: endDate,
      );
});
