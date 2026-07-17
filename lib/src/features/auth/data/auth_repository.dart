import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

// مزود مستودع المصادقة لجعل كلاس AuthRepository قابلاً للاستخدام في أي مكان
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// مستودع عمليات المصادقة والتعامل مع الجلسات
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // مراقبة حالة الجلسة النشطة (هل تم تسجيل الدخول مسبقاً؟)
  Session? get currentSession => _supabase.auth.currentSession;

  // جلب معرف العميل الحالي
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // تسجيل حساب جديد (طبيب أو سكرتيرة)
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'doctor' or 'secretary'
    String? clinicName,   // required if doctor
    String? inviteCode,   // required if secretary
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          if (clinicName != null) 'clinic_name': clinicName,
          if (inviteCode != null) 'invite_code': inviteCode,
        },
      );

      if (response.user == null) {
        throw Exception('فشل إنشاء الحساب.');
      }

      // جلب بيانات البروفايل الذي أنشأه التريجر تلقائياً في جدول users
      return await getUserProfile(response.user!.id);
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

  // جلب بيانات البروفايل من قاعدة البيانات لـ User معين
  Future<UserModel> getUserProfile(String userId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    
    return UserModel.fromJson(data);
  }

  // تحديث صلاحيات موظف أو تعطيل حسابه (للطبيب فقط)
  Future<void> updateUserPermissions({
    required String userId,
    required bool isActive,
    required bool canDeleteAppointments,
    required bool canViewReports,
  }) async {
    await _supabase.from('users').update({
      'is_active': isActive,
      'can_delete_appointments': canDeleteAppointments,
      'can_view_reports': canViewReports,
    }).eq('id', userId);
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
}
