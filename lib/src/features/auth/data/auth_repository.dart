import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/user_model.dart';

// مزود مستودع المصادقة لجعل كلاس AuthRepository قابلاً للاستخدام في أي مكان
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// نتيجة عملية إنشاء الحساب
class SignUpResult {
  final UserModel? user;
  final bool isEmailVerificationRequired;

  SignUpResult({
    required this.user,
    required this.isEmailVerificationRequired,
  });
}

// مستودع عمليات المصادقة والتعامل مع الجلسات
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // مراقبة حالة الجلسة النشطة (هل تم تسجيل الدخول مسبقاً؟)
  Session? get currentSession => _supabase.auth.currentSession;

  // جلب معرف العميل الحالي
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // تسجيل حساب جديد (طبيب أو سكرتيرة)
  String? _formatE164Phone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final String trimmed = phone.trim();
    final String clean = trimmed.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('01') && clean.length == 11) {
      return '+2$clean';
    } else if (clean.startsWith('201') && clean.length == 12) {
      return '+$clean';
    } else if (trimmed.startsWith('+')) {
      return '+$clean';
    } else if (clean.length >= 8) {
      return '+20$clean';
    }
    return trimmed;
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'doctor' or 'secretary'
    String? phone,
    String? clinicName,   // required if doctor
    String? inviteCode,   // required if secretary
  }) async {
    try {
      final String? formattedPhone = _formatE164Phone(phone);

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          if (formattedPhone != null) 'phone': formattedPhone,
          if (clinicName != null) 'clinic_name': clinicName,
          if (inviteCode != null) 'invite_code': inviteCode,
        },
      );

      if (response.user == null) {
        throw Exception('فشل إنشاء الحساب.');
      }

      // إذا كانت ميزة التحقق من البريد الإلكتروني مفعلة في Supabase، لن نحصل على جلسة (session) مباشرة
      if (response.session == null) {
        return SignUpResult(
          user: null,
          isEmailVerificationRequired: true,
        );
      }

      // إذا حصلنا على جلسة مباشرة، فهذا يعني أن التحقق غير مطلوب وتم تسجيل الدخول تلقائياً
      final userProfile = await getUserProfile(response.user!.id);
      return SignUpResult(
        user: userProfile,
        isEmailVerificationRequired: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // تسجيل الدخول في Supabase Auth (يتم حفظ الجلسة تلقائياً في التخزين المحلي للمكتبة)
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('فشل تسجيل الدخول: المستخدم غير موجود.');
      }

      // جلب بيانات البروفايل الخاص بالمستخدم من جدول public.users للوصول إلى clinic_id والـ role
      return await getUserProfile(response.user!.id);
    } catch (e) {
      rethrow;
    }
  }

  // تسجيل الدخول باستخدام Google
  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.clinicmanagement://login-callback',
      );
    } catch (e) {
      rethrow;
    }
  }

  // جلب بيانات البروفايل من قاعدة البيانات لـ User معين
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserModel.fromJson(data);
      }
    } catch (e) {
      print('getUserProfile error: $e');
    }

    // Fallback if RLS or timing delays row retrieval during initial signup/OTP
    final currentUser = _supabase.auth.currentUser;
    final meta = currentUser?.userMetadata ?? {};

    return UserModel(
      id: userId,
      clinicId: meta['clinic_id'] as String? ?? '',
      role: meta['role'] as String? ?? 'doctor',
      fullName: meta['full_name'] as String? ?? 'مستخدم جديد',
      phone: meta['phone'] as String? ?? currentUser?.phone,
      isActive: true,
      canDeleteAppointments: true,
      canViewReports: true,
      createdAt: DateTime.now(),
    );
  }

  // تحديث صلاحيات موظف أو تعطيل حسابه (للطبيب فقط)
  Future<void> updateUserPermissions({
    required String userId,
    required bool isActive,
    required bool canDeleteAppointments,
    required bool canViewReports,
    bool canEditServices = false,
    bool canViewMedicalHistory = false,
    bool canEditMedicalNotes = false,
    bool canCancelAppointments = true,
  }) async {
    try {
      await _supabase.from('users').update({
        'is_active': isActive,
        'can_delete_appointments': canDeleteAppointments,
        'can_view_reports': canViewReports,
        'can_edit_services': canEditServices,
        'can_view_medical_history': canViewMedicalHistory,
        'can_edit_medical_notes': canEditMedicalNotes,
        'can_cancel_appointments': canCancelAppointments,
      }).eq('id', userId);
    } catch (e) {
      await _supabase.from('users').update({
        'is_active': isActive,
        'can_delete_appointments': canDeleteAppointments,
        'can_view_reports': canViewReports,
      }).eq('id', userId);
    }
  }

  // جلب كافة الموظفين في نفس العيادة (للطبيب لإدارة الصلاحيات)
  Future<List<UserModel>> getClinicStaff(String clinicId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  // جلب كود الدعوة الخاص بالعيادة
  Future<String> getClinicInviteCode(String clinicId) async {
    final response = await _supabase
        .from('clinics')
        .select('invite_code')
        .eq('id', clinicId)
        .single();
    return response['invite_code'] as String;
  }

  // تسجيل الخروج وتنظيف الجلسة المخزنة محلياً
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // التحقق من رمز OTP المرسل للإيميل (6 أرقام)
  Future<UserModel?> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      // 1. تجربة نوع OtpType.signup
      try {
        final AuthResponse response = await _supabase.auth.verifyOTP(
          email: email,
          token: token.trim(),
          type: OtpType.signup,
        );

        if (response.user != null) {
          return await getUserProfile(response.user!.id);
        }
      } catch (e1) {
        final errStr = e1.toString().toLowerCase();
        if (errStr.contains('already confirmed') || errStr.contains('already verified')) {
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null) {
            return await getUserProfile(currentUser.id);
          }
        }
      }

      // 2. تجربة النوع الافتراضي OtpType.email إذا فشل signup
      try {
        final AuthResponse response2 = await _supabase.auth.verifyOTP(
          email: email,
          token: token.trim(),
          type: OtpType.email,
        );

        if (response2.user != null) {
          return await getUserProfile(response2.user!.id);
        }
      } catch (e2) {
        final errStr = e2.toString().toLowerCase();
        if (errStr.contains('already confirmed') || errStr.contains('already verified')) {
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null) {
            return await getUserProfile(currentUser.id);
          }
        }
      }

      // في حال وُجدت جلسة قائمة للمستخدم المسجل بالفعل
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        return await getUserProfile(currentUser.id);
      }

      throw Exception('رمز التحقق غير صحيح أو انتهت صلاحيته.');
    } catch (e) {
      rethrow;
    }
  }

  // إعادة إرسال رمز OTP للبريد الإلكتروني
  Future<void> resendEmailOtp(String email) async {
    try {
      await _supabase.auth.resend(
        email: email,
        type: OtpType.signup,
      );
    } catch (_) {
      await _supabase.auth.signInWithOtp(email: email);
    }
  }

  // ربط أو تغير عيادة المساعد بواسطة كود الدعوة
  Future<Map<String, dynamic>> joinClinicWithInviteCode(String inviteCode) async {
    try {
      final response = await _supabase.rpc(
        'switch_user_clinic',
        params: {'p_invite_code': inviteCode.trim()},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الربط بالعيادة: $e'};
    }
  }
}
