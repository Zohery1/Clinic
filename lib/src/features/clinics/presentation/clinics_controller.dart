import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/login_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../data/clinics_repository.dart';
import '../domain/branch_model.dart';
import '../domain/clinic_summary_model.dart';
import '../../appointments/presentation/appointments_controller.dart';

// مزود لجلب جميع عيادات المستخدم الحالي
final userClinicsProvider = FutureProvider<List<ClinicSummaryModel>>((ref) async {
  final repository = ref.watch(clinicsRepositoryProvider);
  return repository.getUserClinics();
});

// مزود لتحديد العيادة النشطة حالياً للمستخدم كـ Summary
final activeClinicSummaryProvider = Provider<ClinicSummaryModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final clinicsAsync = ref.watch(userClinicsProvider);
  return clinicsAsync.when(
    data: (clinics) {
      if (clinics.isEmpty) return null;
      final targetClinicId = user.activeClinicId ?? user.clinicId;
      return clinics.firstWhere(
        (c) => c.clinicId == targetClinicId,
        orElse: () => clinics.first,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// مزود لجلب فروع عيادة محددة
final clinicBranchesProvider = FutureProvider.family<List<BranchModel>, String>((ref, clinicId) async {
  final repository = ref.watch(clinicsRepositoryProvider);
  return repository.getClinicBranches(clinicId);
});

// مزود لفلترة الفرع المختار في قائمة المواعيد والتقارير (null = كل الفروع)
final selectedBranchFilterProvider = StateProvider<String?>((ref) => null);

// دالة مساعدة لتحديد الفرع المطبق على الفلترة
String? getEffectiveBranchIdForAppointments(Ref ref) {
  final branchFilter = ref.watch(selectedBranchFilterProvider);
  if (branchFilter != null && branchFilter.isNotEmpty) {
    return branchFilter;
  }
  return null;
}

// مزود التحكم في عمليات العيادات والفروع
final clinicsControllerProvider = StateNotifierProvider<ClinicsController, AsyncValue<void>>((ref) {
  return ClinicsController(ref);
});

class ClinicsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ClinicsController(this._ref) : super(const AsyncValue.data(null));

  ClinicsRepository get _repository => _ref.read(clinicsRepositoryProvider);

  Future<void> _refreshCurrentUser() async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final uid = authRepo.currentUserId;
      if (uid != null) {
        final updatedUser = await authRepo.getUserProfile(uid);
        _ref.read(currentUserProvider.notifier).state = updatedUser;
      }
    } catch (_) {}
  }

  // التبديل بين العيادات النشطة
  Future<bool> switchActiveClinic(String clinicId, {String? branchId}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.switchActiveClinic(
        clinicId: clinicId,
        branchId: branchId,
      );

      if (res['success'] == true) {
        // تعيين فلتر الفرع المختار أو الفرع العائد من قاعدة البيانات
        _ref.read(selectedBranchFilterProvider.notifier).state = branchId ?? res['branch_id']?.toString();
        _ref.read(selectedDoctorFilterProvider.notifier).state = null;

        // تحديث بيانات المستخدم والعيادات والمواعيد
        await _refreshCurrentUser();
        _ref.invalidate(userClinicsProvider);
        _ref.invalidate(clinicBranchesProvider);
        invalidateAppointmentsAndReports(_ref);

        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل التبديل إلى العيادة';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // إنشاء عيادة جديدة للمستخدم
  Future<bool> createNewClinic(String clinicName) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.createNewClinic(clinicName);
      if (res['success'] == true) {
        // إعادة تعيين الفلاتر
        _ref.read(selectedBranchFilterProvider.notifier).state = null;
        _ref.read(selectedDoctorFilterProvider.notifier).state = null;

        // تحديث البيانات
        await _refreshCurrentUser();
        _ref.invalidate(userClinicsProvider);
        _ref.invalidate(clinicBranchesProvider);
        invalidateAppointmentsAndReports(_ref);

        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل إنشاء العيادة';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // الانضمام لعيادة أخرى بكود الدعوة
  Future<bool> joinClinic(String inviteCode, {String? role}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.joinClinicWithInviteCode(
        inviteCode: inviteCode,
        role: role ?? 'doctor',
      );
      if (res['success'] == true) {
        // إعادة تعيين الفلاتر
        _ref.read(selectedBranchFilterProvider.notifier).state = null;
        _ref.read(selectedDoctorFilterProvider.notifier).state = null;

        // تحديث البيانات
        await _refreshCurrentUser();
        _ref.invalidate(userClinicsProvider);
        _ref.invalidate(clinicBranchesProvider);
        invalidateAppointmentsAndReports(_ref);

        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل الانضمام للعيادة';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // إنشاء فرع جديد
  Future<bool> createBranch({
    required String clinicId,
    required String name,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.createBranch(
        clinicId: clinicId,
        name: name,
        address: address,
        phone: phone,
        isMain: isMain,
      );
      if (res['success'] == true) {
        _ref.invalidate(clinicBranchesProvider(clinicId));
        _ref.invalidate(userClinicsProvider);
        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل إنشاء الفرع';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // تعديل فرع
  Future<bool> updateBranch({
    required String clinicId,
    required String branchId,
    required String name,
    String? address,
    String? phone,
    bool isMain = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.updateBranch(
        branchId: branchId,
        name: name,
        address: address,
        phone: phone,
        isMain: isMain,
      );
      if (res['success'] == true) {
        _ref.invalidate(clinicBranchesProvider(clinicId));
        _ref.invalidate(userClinicsProvider);
        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل تحديث الفرع';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  // حذف فرع
  Future<bool> deleteBranch({required String clinicId, required String branchId}) async {
    state = const AsyncValue.loading();
    try {
      final res = await _repository.deleteBranch(branchId);
      if (res['success'] == true) {
        _ref.invalidate(clinicBranchesProvider(clinicId));
        _ref.invalidate(userClinicsProvider);
        state = const AsyncValue.data(null);
        return true;
      } else {
        throw res['message'] ?? 'فشل حذف الفرع';
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}
