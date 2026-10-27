import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../../main.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../auth/presentation/login_screen.dart';
import '../../../auth/presentation/join_clinic_screen.dart';
import '../../../clinics/presentation/clinics_controller.dart';

/// نوافذ الحوار الخاصة بالإعدادات (تسجيل الخروج ومغادرة العيادة)
class SettingsDialogs {
  static void showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: const Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('خروج', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  static void showLeaveClinicDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final activeClinicId = user?.activeClinicId ?? user?.clinicId;

    if (user == null || activeClinicId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
              SizedBox(width: 8),
              Text(
                'الخروج من العيادة',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'تحذير: هذا الإجراء سيقوم بفصل حسابك عن هذه العيادة نهائياً ومغادرتها. في حال كان لديك عيادات أخرى مسجلة بحسابك فسيتم التبديل إليها تلقائياً. هل أنت متأكد؟',
            style: TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final res = await ref
                      .read(clinicsControllerProvider.notifier)
                      .leaveClinic(activeClinicId);

                  if (context.mounted) {
                    final message = res['message']?.toString() ?? 'تمت مغادرة العيادة بنجاح';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message, style: GoogleFonts.cairo()),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );

                    final hasOtherClinics = res['has_other_clinics'] == true;
                    if (!hasOtherClinics) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => JoinClinicScreen(
                            userName: user.fullName,
                            onRefresh: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const AuthGate()),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                        (route) => false,
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('نعم، مغادرة العيادة', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
