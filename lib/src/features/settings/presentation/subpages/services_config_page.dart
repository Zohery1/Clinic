import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/widgets/clinic_dialog.dart';
import '../../../../core/widgets/clinic_toast.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/login_controller.dart';
import '../../../appointments/domain/appointment_type_model.dart';
import '../../../appointments/domain/service_model.dart';
import '../../../reports/data/reports_repository.dart';
import '../../../reports/presentation/reports_controller.dart';

class ServicesConfigPage extends ConsumerStatefulWidget {
  const ServicesConfigPage({super.key});

  @override
  ConsumerState<ServicesConfigPage> createState() => _ServicesConfigPageState();
}

class _ServicesConfigPageState extends ConsumerState<ServicesConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildPriceWidget(BuildContext context, double price) {
    if (price <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.isDark(context)
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.successSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'مجانًا',
          style: GoogleFonts.cairo(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price.toStringAsFixed(0),
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'ج.م',
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas(context),
        body: Center(
          child: Text('يرجى تسجيل الدخول', style: GoogleFonts.cairo()),
        ),
      );
    }

    final isDoctor = user.role == UserRole.doctor;
    final canManageServices = isDoctor || user.canEditServices;
    final appointmentTypesAsync = ref.watch(appointmentTypesProvider);
    final servicesAsync = ref.watch(servicesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.canvas(context),
        appBar: AppBar(
          title: Text(
            'أسعار الكشوفات والخدمات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'أسعار الكشوفات'),
              Tab(text: 'الخدمات الطبية الإضافية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAppointmentTypesTab(appointmentTypesAsync, canManageServices),
            _buildServicesTab(servicesAsync, canManageServices),
          ],
        ),
        floatingActionButton: canManageServices
            ? FloatingActionButton(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                child: const Icon(Icons.add_rounded),
                onPressed: () {
                  if (_tabController.index == 0) {
                    _showAddAppointmentTypeDialog(context, user.clinicId);
                  } else {
                    _showAddServiceDialog(context, user.clinicId);
                  }
                },
              )
            : null,
      ),
    );
  }

  // الكشوفات
  Widget _buildAppointmentTypesTab(
      AsyncValue<List<AppointmentTypeModel>> asyncData, bool canManageServices) {
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'لا توجد أسعار كشوفات مضافة بعد.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final type = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle(context),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildPriceWidget(context, type.price),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (canManageServices)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textSecondary(context),
                          ),
                          onPressed: () => _showEditAppointmentTypeDialog(context, type),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          onPressed: () => _showDeleteAppointmentTypeConfirm(context, type),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Text(
          'خطأ: $err',
          style: GoogleFonts.cairo(color: AppColors.danger),
        ),
      ),
    );
  }

  // الخدمات
  Widget _buildServicesTab(
      AsyncValue<List<ServiceModel>> asyncData, bool canManageServices) {
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'لا توجد خدمات مضافة بعد.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final service = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle(context),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPriceWidget(context, service.price),
                    ],
                  ),
                  if (canManageServices)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textSecondary(context),
                          ),
                          onPressed: () => _showEditServiceDialog(context, service),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          onPressed: () => _showDeleteServiceConfirm(context, service),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Text(
          'خطأ: $err',
          style: GoogleFonts.cairo(color: AppColors.danger),
        ),
      ),
    );
  }

  // ─── الحوارات المنبثقة للعمليات ───

  void _showAddAppointmentTypeDialog(BuildContext context, String clinicId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.medical_services_outlined,
      title: 'إضافة نوع كشف جديد',
      subtitle: 'سيُضاف للقائمة المتاحة عند حجز المواعيد',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الكشف',
              hint: 'مثال: كشف استشاري، متابعة',
              prefixIcon: Icons.badge_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الكشف' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'سعر الكشف (ج.م)',
              hint: '0',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary(context))),
        ),
        SettingsSaveButton(
          label: 'حفظ',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final name = nameCtrl.text.trim();
            final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
            await ref.read(reportsRepositoryProvider).addAppointmentType(
                  clinicId: clinicId, name: name, price: price);
            _invalidateTypes();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showEditAppointmentTypeDialog(BuildContext context, dynamic type) {
    final nameCtrl = TextEditingController(text: type.name);
    final priceCtrl = TextEditingController(text: type.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.edit_outlined,
      title: 'تعديل نوع الكشف',
      subtitle: type.name,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الكشف',
              prefixIcon: Icons.badge_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'السعر (ج.م)',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary(context))),
        ),
        SettingsSaveButton(
          label: 'تعديل',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).updateAppointmentType(
                  id: type.id,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateTypes();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showDeleteAppointmentTypeConfirm(BuildContext context, dynamic type) {
    ClinicDialog.confirm(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'حذف نوع الكشف',
      description: 'هل أنت متأكد من حذف نوع الكشف "${type.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(reportsRepositoryProvider).deleteAppointmentType(type.id);
        _invalidateTypes();
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, String clinicId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && currentUser.role == UserRole.secretary && !currentUser.canEditServices) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ليس لديك صلاحية لإضافة أو تعديل الخدمات والأسعار. يرجى مراجعة الطبيب.',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.add_circle_outline_rounded,
      title: 'إضافة خدمة طبية جديدة',
      subtitle: 'مثال: رسم قلب، غيار جروح، حقنة',
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الخدمة',
              hint: 'مثال: رسم قلب ECG',
              prefixIcon: Icons.medical_services_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال اسم الخدمة' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'سعر الخدمة (ج.م)',
              hint: '0',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary(context))),
        ),
        SettingsSaveButton(
          label: 'حفظ',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).addService(
                  clinicId: clinicId,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateServices();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showEditServiceDialog(BuildContext context, dynamic service) {
    final nameCtrl = TextEditingController(text: service.name);
    final priceCtrl = TextEditingController(text: service.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    ClinicDialog.show(
      context: context,
      icon: Icons.edit_outlined,
      title: 'تعديل الخدمة الطبية',
      subtitle: service.name,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClinicFormField(
              label: 'اسم الخدمة',
              prefixIcon: Icons.medical_services_outlined,
              controller: nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            const SizedBox(height: 14),
            ClinicFormField(
              label: 'السعر (ج.م)',
              prefixIcon: Icons.payments_outlined,
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'يرجى إدخال السعر';
                if (double.tryParse(v.trim()) == null) return 'يرجى إدخال رقم صحيح';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary(context))),
        ),
        SettingsSaveButton(
          label: 'تعديل',
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            await ref.read(reportsRepositoryProvider).updateService(
                  id: service.id,
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0);
            _invalidateServices();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _showDeleteServiceConfirm(BuildContext context, dynamic service) {
    ClinicDialog.confirm(
      context: context,
      icon: Icons.delete_outline_rounded,
      title: 'حذف الخدمة الطبية',
      description: 'هل أنت متأكد من حذف الخدمة "${service.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      isDangerous: true,
      onConfirm: () async {
        await ref.read(reportsRepositoryProvider).deleteService(service.id);
        _invalidateServices();
      },
    );
  }

  void _invalidateTypes() {
    ref.invalidate(appointmentTypesProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(monthRevenueProvider);
    ref.invalidate(weeklyRevenueProvider);
    ref.invalidate(dailyStatsProvider);
    ref.invalidate(monthlyStatsProvider);
  }

  void _invalidateServices() {
    ref.invalidate(servicesProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(monthRevenueProvider);
    ref.invalidate(weeklyRevenueProvider);
    ref.invalidate(dailyStatsProvider);
    ref.invalidate(monthlyStatsProvider);
  }
}

// زر حفظ مع loading state — مستخدم في حوارات الإعدادات
class SettingsSaveButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;

  const SettingsSaveButton({super.key, required this.label, required this.onPressed});

  @override
  State<SettingsSaveButton> createState() => _SettingsSaveButtonState();
}

class _SettingsSaveButtonState extends State<SettingsSaveButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } catch (e) {
                if (context.mounted) {
                  ClinicToast.showError(context, 'خطأ: $e');
                }
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      child: _loading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(widget.label, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
    );
  }
}
