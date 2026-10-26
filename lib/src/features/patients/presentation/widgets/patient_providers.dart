import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appointments/data/appointment_repository.dart';
import '../../../appointments/domain/appointment_model.dart';
import '../../../appointments/domain/appointment_service_model.dart';

/// مزود لجلب تاريخ مواعيد المريض بالكامل (منتهية فقط)
final patientAppointmentsProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, patientId) async {
  final all = await ref.watch(appointmentRepositoryProvider).getPatientAppointments(patientId);
  final completed = all.where((app) => app.status == 'completed').toList();
  if (completed.isNotEmpty) return completed;
  return all;
});

/// مزود لجلب الخدمات الطبية الخاصة بالزيارة
final appointmentServicesProvider = FutureProvider.family<List<AppointmentServiceModel>, String>((ref, appointmentId) async {
  return ref.watch(appointmentRepositoryProvider).getAppointmentServices(appointmentId);
});
