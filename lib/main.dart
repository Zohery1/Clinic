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
  bool _isSubscribed = true;
  String _clinicName = '';
  DateTime? _subscriptionEndDate;
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
        final res = await Supabase.instance.client
            .from('clinics')
            .select('name, is_active, subscription_end_date')
            .eq('id', user.clinicId)
            .single();

        final isActive = res['is_active'] as bool? ?? true;
        final endDateStr = res['subscription_end_date'] as String?;
        final endDate = endDateStr != null ? DateTime.tryParse(endDateStr) : null;
        final isExpired = endDate != null && endDate.isBefore(DateTime.now());

        _clinicName = res['name'] as String? ?? 'العيادة';
        _isClinicActive = isActive;
        _subscriptionEndDate = endDate;
        _isSubscribed = isActive && !isExpired;
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
      if (!_isSubscribed) {
        return SubscriptionGateScreen(
          clinicName: _clinicName,
          subscriptionEndDate: _subscriptionEndDate,
          isActive: _isClinicActive,
          onRefresh: () async {
            setState(() => _isInitializing = true);
            await _checkInitialSession();
          },
        );
      }
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}

