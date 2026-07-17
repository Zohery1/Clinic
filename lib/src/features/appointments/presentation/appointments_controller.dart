import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/login_controller.dart';
import '../data/appointment_repository.dart';
import '../domain/appointment_model.dart';
import '../domain/appointment_service_model.dart';

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
final todayAppointmentsProvider = FutureProvider.autoDispose<List<AppointmentModel>>((ref) async {
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
final dashboardFilterProvider = StateProvider<String>((ref) => 'all');
