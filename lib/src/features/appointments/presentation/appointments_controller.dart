import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/login_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/appointment_service_model.dart';
import '../../reports/presentation/reports_controller.dart';

// مزود لجلب الخدمات المقدمة لحجز معين
final appointmentServicesProvider = FutureProvider.autoDispose.family<List<AppointmentServiceModel>, String>((ref, appointmentId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentServices(appointmentId);
});

// مزود لتخزين التاريخ المحدد حالياً في شاشة المواعيد
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// مزود لجلب المواعيد للتاريخ المحدد تلقائياً
final todayAppointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  // مراقبة المستخدم الحالي لجلب معرف العيادة الخاصة به تلقائياً
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }

  final selectedDate = ref.watch(selectedDateProvider);
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentsByDate(user.clinicId, selectedDate);
});

// مزود لجلب مواعيد تاريخ محدد (لتجنب حجز المواعيد المتعارضة)
final appointmentsForDateProvider = FutureProvider.autoDispose.family<List<AppointmentModel>, DateTime>((ref, date) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentsByDate(user.clinicId, date);
});

// مزود لتخزين فلتر قائمة المرضى المحدد حالياً
final dashboardFilterProvider = StateProvider<String>((ref) => 'confirmed');

// مزود الاستماع التلقائي الفوري لتعديلات المواعيد عبر الأجهزة المختلفة (دكتور / مساعد) مع ميزة الـ Debounce لتجنب البطء
final realtimeAppointmentsSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final supabase = Supabase.instance.client;
  final channel = supabase.channel('realtime:appointments:${user.clinicId}');
  Timer? debounceTimer;

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'appointments',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'clinic_id',
      value: user.clinicId,
    ),
    callback: (payload) {
      // تجميع التغييرات المتقاربة زمنياً وتأخير التحديث 500 ملي ثانية لمنع غمر السيرفر بالطلبات المتكررة
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        invalidateAppointmentsAndReports(ref);
      });
    },
  ).subscribe();

  ref.onDispose(() {
    debounceTimer?.cancel();
    supabase.removeChannel(channel);
  });
});

void invalidateAppointmentsAndReports(dynamic ref) {
  ref.invalidate(todayAppointmentsProvider);
  ref.invalidate(appointmentsForDateProvider);
  ref.invalidate(todayRevenueProvider);
  ref.invalidate(monthRevenueProvider);
  ref.invalidate(weeklyRevenueProvider);
  ref.invalidate(sixWeeksRevenueProvider);
  ref.invalidate(monthlyStatsProvider);
  ref.invalidate(dailyStatsProvider);
  ref.invalidate(detailedReportProvider);
}
