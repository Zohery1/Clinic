import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'src/core/constants/supabase_config.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'src/features/auth/presentation/login_controller.dart';
import 'src/features/auth/presentation/subscription_gate_screen.dart';
import 'src/features/auth/presentation/top_up_subscription_screen.dart';
import 'src/features/auth/presentation/pending_activation_screen.dart';
import 'src/features/dashboard/presentation/dashboard_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'عيادتي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

/// بوابة المصادقة — توجيه تلقائي حسب حالة الجلسة والاشتراك
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isInitializing = true;
  bool _isLoggedIn = false;
  String _clinicName = '';
  String _inviteCode = '';
  String _clinicId = '';
  DateTime? _subscriptionEndDate;
  String _subscriptionStatus = 'active'; // 'active', 'pending_activation', 'expired', 'suspended'
  bool _isClinicActive = true;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final success = await ref.read(loginControllerProvider.notifier).tryAutoLogin();
        if (success) {
          await _verifySubscription();
        }
        if (mounted) {
          setState(() {
            _isLoggedIn = success;
            _isInitializing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isInitializing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _verifySubscription() async {
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _clinicId = user.clinicId;
        final res = await Supabase.instance.client
            .from('clinics')
            .select('name, invite_code, is_active, subscription_end_date, subscription_status')
            .eq('id', user.clinicId)
            .single();

        final isActive = res['is_active'] as bool? ?? true;
        final endDateStr = res['subscription_end_date'] as String?;
        final statusStr = (res['subscription_status'] as String? ?? 'active').toLowerCase();
        final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

        _clinicName = res['name'] as String? ?? 'العيادة';
        _inviteCode = res['invite_code'] as String? ?? '';
        _isClinicActive = isActive;
        _subscriptionEndDate = endDate;
        _subscriptionStatus = statusStr;
      }
    } catch (_) {
      // وفي حالة وجود خطأ نعتمد الحالة الافتراضية
    }
  }

  Future<void> _checkInitialSession() async {
    try {
      final success = await ref.read(loginControllerProvider.notifier).tryAutoLogin();
      if (success) {
        await _verifySubscription();
      }
      setState(() {
        _isLoggedIn = success;
        _isInitializing = false;
      });
    } catch (_) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      // 1. حساب العيادة معطل من الإدارة
      if (!_isClinicActive || _subscriptionStatus == 'suspended') {
        return SubscriptionGateScreen(
          clinicName: _clinicName,
          subscriptionEndDate: _subscriptionEndDate,
          isActive: false,
          onRefresh: () async {
            setState(() => _isInitializing = true);
            await _checkInitialSession();
          },
        );
      }

      // 2. حالة الانتظار لحين تفعيل الفاتورة
      if (_subscriptionStatus == 'pending_activation') {
        return PendingActivationScreen(
          clinicName: _clinicName,
          inviteCode: _inviteCode,
          onRefresh: () async {
            setState(() => _isInitializing = true);
            await _checkInitialSession();
          },
        );
      }

      // 3. حالة الانتهاء وعدم الدفع (Top Up)
      final isExpired = _subscriptionEndDate != null && _subscriptionEndDate!.isBefore(DateTime.now());
      if (_subscriptionStatus == 'expired' || isExpired) {
        return TopUpSubscriptionScreen(
          clinicName: _clinicName,
          inviteCode: _inviteCode,
          clinicId: _clinicId,
          onRefresh: () async {
            setState(() => _isInitializing = true);
            await _checkInitialSession();
          },
        );
      }

      // 4. الاشتراك نشط (مع التمرير لبيانات الانتهاء لحساب إنذار الـ 48 ساعة)
      return DashboardScreen(
        subscriptionEndDate: _subscriptionEndDate,
        inviteCode: _inviteCode,
        clinicName: _clinicName,
        clinicId: _clinicId,
      );
    } else {
      return const LoginScreen();
    }
  }
}
