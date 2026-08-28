import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user_model.dart';

class ClinicDetailsPage extends ConsumerStatefulWidget {
  const ClinicDetailsPage({super.key});

  @override
  ConsumerState<ClinicDetailsPage> createState() => _ClinicDetailsPageState();
}

class _ClinicDetailsPageState extends ConsumerState<ClinicDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _doctorNameController.text = user.fullName;
      _loadClinicName(user.clinicId);
    }
  }

  void _loadClinicName(String clinicId) async {
    try {
      final res = await Supabase.instance.client
          .from('clinics')
          .select('name')
          .eq('id', clinicId)
          .single();
      _clinicNameController.text = res['name'] as String;
    } catch (_) {}
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      try {
        // تحديث اسم الطبيب
        await Supabase.instance.client
            .from('users')
            .update({'full_name': _doctorNameController.text.trim()})
            .eq('id', user.id);

        // تحديث اسم العيادة (للطبيب فقط)
        if (user.role == UserRole.doctor) {
          await Supabase.instance.client
              .from('clinics')
              .update({'name': _clinicNameController.text.trim()})
              .eq('id', user.clinicId);
        }

        // تحديث بروفايل المستخدم محلياً
        final updatedUser = await ref.read(authRepositoryProvider).getUserProfile(user.id);
        ref.read(currentUserProvider.notifier).state = updatedUser;

        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(duration: Duration(seconds: 2), content: Text('تم حفظ البيانات بنجاح'), backgroundColor: AppTheme.success),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            SnackBar(duration: const Duration(seconds: 2), content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: AppTheme.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('بيانات العيادة والدكتور')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctorNameController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    labelText: 'اسم الطبيب / المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clinicNameController,
                  enabled: user?.role == UserRole.doctor,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: 'اسم العيادة / المركز الطبي',
                    prefixIcon: const Icon(Icons.business_rounded),
                    helperText: user?.role == UserRole.secretary
                        ? 'تنبيه: السكرتير لا يمكنه تغيير اسم العيادة'
                        : null,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'يرجى إدخال اسم العيادة' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ البيانات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
