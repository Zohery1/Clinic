import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// مزود حالة المستخدم الحالي المسجل دخوله
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// كلاس يمثل الحالات المختلفة لشاشة تسجيل الدخول
class LoginState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// متحكم شاشة تسجيل الدخول لإدارة الحالات المختلفة واستدعاء المستودع
class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final StateController<UserModel?> _currentUserNotifier;

  LoginController(this._authRepository, this._currentUserNotifier) : super(LoginState());

  Future<void> login(String email, String password) async {
    // التحقق من المدخلات الأساسية
    if (email.trim().isEmpty || password.trim().isEmpty) {
      state = LoginState(errorMessage: 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // محاولة تسجيل الدخول وجلب الملف الشخصي للمستخدم
      final userModel = await _authRepository.signIn(
        email: email.trim(),
        password: password,
      );

      // حفظ بيانات المستخدم الحالي في الـ Provider العام
      _currentUserNotifier.state = userModel;
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'فشل تسجيل الدخول: يرجى التحقق من صحة البيانات أو الاتصال بالإنترنت.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? clinicName,
    String? inviteCode,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty || fullName.trim().isEmpty) {
      state = LoginState(errorMessage: 'يرجى ملء جميع الحقول المطلوبة');
      return;
    }
    if (role == 'doctor' && (clinicName == null || clinicName.trim().isEmpty)) {
      state = LoginState(errorMessage: 'يرجى إدخال اسم العيادة لتسجيل حساب طبيب');
      return;
    }
    if (role == 'secretary' && (inviteCode == null || inviteCode.trim().isEmpty)) {
      state = LoginState(errorMessage: 'يرجى إدخال كود الدعوة للانضمام للعيادة');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userModel = await _authRepository.signUp(
        email: email.trim(),
        password: password,
        fullName: fullName.trim(),
        role: role,
        clinicName: clinicName?.trim(),
        inviteCode: inviteCode?.trim(),
      );

      _currentUserNotifier.state = userModel;
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'فشل إنشاء الحساب: ${e.toString().replaceAll('Exception:', '')}',
      );
    }
  }

  // محاولة استعادة الجلسة الحالية تلقائياً عند تشغيل التطبيق
  Future<bool> tryAutoLogin() async {
    final userId = _authRepository.currentUserId;
    if (userId != null) {
      try {
        final userModel = await _authRepository.getUserProfile(userId);
        _currentUserNotifier.state = userModel;
        return true;
      } catch (_) {
        // فشل جلب البروفايل، الجلسة قد تكون غير صالحة
        return false;
      }
    }
    return false;
  }
}

// مزود متحكم شاشة تسجيل الدخول
final loginControllerProvider = StateNotifierProvider<LoginController, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final currentUserNotifier = ref.watch(currentUserProvider.notifier);
  return LoginController(authRepository, currentUserNotifier);
});
