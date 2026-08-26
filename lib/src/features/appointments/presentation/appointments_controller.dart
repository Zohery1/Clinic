import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/domain/user_model.dart';
import '../../clinics/presentation/clinics_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/appointment_service_model.dart';
import '../../reports/presentation/reports_controller.dart';

// مزود لجلب الخدمات المقدمة لحجز معين
final appointmentServicesProvider = FutureProvider.family<List<AppointmentServiceModel>, String>((ref, appointmentId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointmentServices(appointmentId);
});

// مزود لتخزين التاريخ المحدد حالياً في شاشة المواعيد
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// مزود لتحديد الطبيب المختار لفلترة المواعيد (null = الكل أو الطبيب الافتراضي)
final selectedDoctorFilterProvider = StateProvider<String?>((ref) => null);

// دالة مساعدة لتحديد الطبيب المطبق على استعلام المواعيد
String? getEffectiveDoctorIdForAppointments(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final filter = ref.watch(selectedDoctorFilterProvider);
  if (filter != null) {
    return filter.isEmpty ? null : filter;
  }
  // إذا كان المستخدم طبيب عادي ولا يملك صلاحية رؤية التقارير/الطابور العام
  if (user.role == UserRole.doctor && !user.isOwner && !user.canViewReports) {
    return user.id;
  }
  return null;
}

// مزود لجلب المواعيد للتاريخ المحدد تلقائياً مع دعم فلتر الطبيب والفرع
final todayAppointmentsProvider = FutureProvider<List<AppointmentModel>>((ref) async {
  // مراقبة المستخدم الحالي لجلب معرف العيادة الخاصة به تلقائياً
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return [];
  }

  final selectedDate = ref.watch(selectedDateProvider);
  final repository = ref.watch(appointmentRepositoryProvider);
  final doctorId = getEffectiveDoctorIdForAppointments(ref);
  final branchId = ref.watch(selectedBranchFilterProvider);
  return repository.getAppointmentsByDate(user.clinicId, selectedDate, doctorId: doctorId, branchId: branchId);
});

// مزود لجلب مواعيد تاريخ محدد (لتجنب حجز المواعيد المتعارضة)
final appointmentsForDateProvider = FutureProvider.family<List<AppointmentModel>, DateTime>((ref, date) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repository = ref.watch(appointmentRepositoryProvider);
  final doctorId = getEffectiveDoctorIdForAppointments(ref);
  final branchId = ref.watch(selectedBranchFilterProvider);
  return repository.getAppointmentsByDate(user.clinicId, date, doctorId: doctorId, branchId: branchId);
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
