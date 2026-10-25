import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/clinic_dialog.dart';
import '../../../core/widgets/clinic_toast.dart';
import '../../auth/presentation/login_controller.dart';
import '../../clinics/domain/branch_model.dart';
import '../../clinics/presentation/clinics_controller.dart';
import '../../clinics/presentation/widgets/create_clinic_dialog.dart';

class ClinicBranchesPage extends ConsumerStatefulWidget {
  const ClinicBranchesPage({super.key});

  @override
  ConsumerState<ClinicBranchesPage> createState() => _ClinicBranchesPageState();
}

class _ClinicBranchesPageState extends ConsumerState<ClinicBranchesPage> {
  void _openAddEditBranchDialog([BranchModel? branch]) {
    final nameController = TextEditingController(text: branch?.name ?? '');
    final addressController = TextEditingController(text: branch?.address ?? '');
    final phoneController = TextEditingController(text: branch?.phone ?? '');
    bool isMain = branch?.isMain ?? false;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              branch == null ? Icons.add_business_rounded : Icons.edit_location_alt_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch == null ? 'إضافة فرع جديد' : 'تعديل بيانات الفرع',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'تحديد اسم الفرع وموقعه ومعلومات الاتصال',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Branch Name
                      Text('اسم الفرع *', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'مثال: فرع مدينة نصر',
                          hintStyle: GoogleFonts.cairo(fontSize: 13),
                          prefixIcon: const Icon(Icons.store_mall_directory_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال اسم الفرع' : null,
                      ),
                      const SizedBox(height: 14),

                      // Address
                      Text('العنوان (اختياري)', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addressController,
                        decoration: InputDecoration(
                          hintText: 'مثال: شارع عباس العقاد - الدور الثاني',
                          hintStyle: GoogleFonts.cairo(fontSize: 13),
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      Text('هاتف الفرع (اختياري)', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '01xxxxxxxxx',
                          hintStyle: GoogleFonts.cairo(fontSize: 13),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Is Main Branch Switch
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'تعيين كفرع رئيسي للعيادة',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'الفرع الرئيسي يظهر افتراضياً عند الحجز',
                          style: GoogleFonts.cairo(fontSize: 11, color: theme.hintColor),
                        ),
                        value: isMain,
                        onChanged: (val) => setDialogState(() => isMain = val),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDialogState(() => isSubmitting = true);

                                      final user = ref.read(currentUserProvider);
                                      if (user == null) return;

                                      bool success;
                                      if (branch == null) {
                                        success = await ref
                                            .read(clinicsControllerProvider.notifier)
                                            .createBranch(
                                              clinicId: user.clinicId,
                                              name: nameController.text.trim(),
                                              address: addressController.text.trim().isNotEmpty
                                                  ? addressController.text.trim()
                                                  : null,
                                              phone: phoneController.text.trim().isNotEmpty
                                                  ? phoneController.text.trim()
                                                  : null,
                                              isMain: isMain,
                                            );
                                      } else {
                                        success = await ref
                                            .read(clinicsControllerProvider.notifier)
                                            .updateBranch(
                                              clinicId: user.clinicId,
                                              branchId: branch.id,
                                              name: nameController.text.trim(),
                                              address: addressController.text.trim().isNotEmpty
                                                  ? addressController.text.trim()
                                                  : null,
                                              phone: phoneController.text.trim().isNotEmpty
                                                  ? phoneController.text.trim()
                                                  : null,
                                              isMain: isMain,
                                            );
                                      }

                                      if (!context.mounted) return;
                                      setDialogState(() => isSubmitting = false);

                                      if (success) {
                                        Navigator.of(ctx).pop();
                                        ClinicToast.showSuccess(
                                          context,
                                          branch == null ? 'تمت إضافة الفرع بنجاح' : 'تم تحديث بيانات الفرع',
                                        );
                                      } else {
                                        final err = ref.read(clinicsControllerProvider).error?.toString() ?? 'حدث خطأ';
                                        ClinicToast.showError(context, err);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      branch == null ? 'إضافة الفرع' : 'حفظ التعديلات',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteBranch(BranchModel branch) {
    if (branch.isMain) {
      ClinicToast.showError(context, 'لا يمكن حذف الفرع الرئيسي للعيادة');
      return;
    }

    ClinicDialog.confirm(
      context: context,
      title: 'حذف الفرع',
      description: 'هل أنت متأكد من رغبتك في حذف فرع "${branch.name}"؟ لن تتأثر سجلات المرضى السابقة.',
      confirmLabel: 'حذف الفرع',
      isDangerous: true,
      onConfirm: () async {
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        final success = await ref
            .read(clinicsControllerProvider.notifier)
            .deleteBranch(clinicId: user.clinicId, branchId: branch.id);

        if (!mounted) return;
        if (success) {
          ClinicToast.showSuccess(context, 'تم حذف الفرع بنجاح');
        } else {
          final err = ref.read(clinicsControllerProvider).error?.toString() ?? 'فشل حذف الفرع';
          ClinicToast.showError(context, err);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }

    if (!user.isOwner) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'إدارة الفروع والعيادات',
              style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_rounded, size: 48, color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هذه الصفحة مخصصة لمالك العيادة فقط',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يمكنك الوصول لإدارة الفروع أو إنشاء العيادات إلا إذا كنت مالك العيادة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 13, color: theme.hintColor),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('رجوع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final branchesAsync = ref.watch(clinicBranchesProvider(user.clinicId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'إدارة فروع العيادة',
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'إنشاء عيادة جديدة',
              icon: const Icon(Icons.add_business_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CreateClinicDialog(),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _openAddEditBranchDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'إضافة فرع',
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ─── أزرار الإجراءات ───
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openAddEditBranchDialog(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'إضافة فرع جديد',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateClinicDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded, size: 20),
                  label: Text(
                    'إنشاء عيادة',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تشترك جميع فروع العيادة في نفس الاشتراك وقاعدة بيانات المرضى، بينما يتم تسجيل كل حجز وإيراد مالي باسم الفرع الخاص به للفلترة والتقارير الدقيقة.',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Branches List
            branchesAsync.when(
              data: (branches) {
                if (branches.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.storefront_rounded, size: 48, color: theme.hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد فروع مسجلة',
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final branch = branches[idx];

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.cardDecoration(context),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: branch.isMain
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store_mall_directory_rounded,
                              color: branch.isMain ? theme.colorScheme.primary : theme.hintColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      branch.name,
                                      style: GoogleFonts.cairo(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    if (branch.isMain) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade700.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'الفرع الرئيسي',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (branch.address != null && branch.address!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 13, color: theme.hintColor),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          branch.address!,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11.5,
                                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (branch.phone != null && branch.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 13, color: theme.hintColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        branch.phone!,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (branch.inviteCode != null && branch.inviteCode!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: branch.inviteCode!));
                                      ClinicToast.showSuccess(context, 'تم نسخ كود دعوة الفرع: ${branch.inviteCode}');
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.vpn_key_rounded, size: 12, color: theme.colorScheme.primary),
                                          const SizedBox(width: 5),
                                          Text(
                                            'كود دعوة الفرع: ${branch.inviteCode}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(Icons.copy_rounded, size: 11, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (branch.inviteCode != null && branch.inviteCode!.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 19),
                                  tooltip: 'نسخ رابط دعوة الفرع',
                                  onPressed: () {
                                    String origin = 'https://myclinic-app.web.app';
                                    try {
                                      if (Uri.base.hasScheme && (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')) {
                                        origin = Uri.base.origin;
                                      }
                                    } catch (_) {}
                                    final inviteLink = "$origin/#/register?invite=${branch.inviteCode}";
                                    Clipboard.setData(ClipboardData(text: inviteLink));
                                    ClinicToast.showSuccess(context, 'تم نسخ رابط الانضمام لـ ${branch.name} بنجاح');
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                tooltip: 'تعديل',
                                onPressed: () => _openAddEditBranchDialog(branch),
                              ),
                              if (!branch.isMain && branches.length > 1)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.red.shade600),
                                  tooltip: 'حذف',
                                  onPressed: () => _confirmDeleteBranch(branch),
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
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('خطأ في تحميل الفروع: $err', style: GoogleFonts.cairo(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
