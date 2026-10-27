import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../reports_controller.dart';

class PettyExpenseItem {
  final String id;
  final String title;
  final double amount;
  final DateTime time;

  PettyExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.time,
  });
}

/// تبويب مطابقة الخزينة والدرج اليومي لمدير العيادة (Cash Drawer Reconciliation Tab)
class CashDrawerReconciliationTab extends ConsumerStatefulWidget {
  const CashDrawerReconciliationTab({super.key});

  @override
  ConsumerState<CashDrawerReconciliationTab> createState() =>
      _CashDrawerReconciliationTabState();
}

class _CashDrawerReconciliationTabState
    extends ConsumerState<CashDrawerReconciliationTab> {
  final TextEditingController _openingFloatCtrl =
      TextEditingController(text: '500');
  final TextEditingController _actualCashCtrl = TextEditingController();
  final TextEditingController _expenseTitleCtrl = TextEditingController();
  final TextEditingController _expenseAmountCtrl = TextEditingController();

  final List<PettyExpenseItem> _expenses = [];
  bool _isClosed = false;

  @override
  void dispose() {
    _openingFloatCtrl.dispose();
    _actualCashCtrl.dispose();
    _expenseTitleCtrl.dispose();
    _expenseAmountCtrl.dispose();
    super.dispose();
  }

  double get _openingFloat {
    final text = _openingFloatCtrl.text.trim();
    if (text.isEmpty || text == '.') return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  double get _actualCash {
    final text = _actualCashCtrl.text.trim();
    if (text.isEmpty || text == '.') return 0.0;
    return double.tryParse(text) ?? 0.0;
  }

  double get _totalExpenses =>
      _expenses.fold<double>(0.0, (acc, item) => acc + item.amount);

  void _addExpense() {
    final title = _expenseTitleCtrl.text.trim();
    final amountText = _expenseAmountCtrl.text.trim();
    final amount = (amountText.isEmpty || amountText == '.')
        ? null
        : double.tryParse(amountText);
    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سبب المصروف ومبلغ صحيح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _expenses.insert(
        0,
        PettyExpenseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          time: DateTime.now(),
        ),
      );
      _expenseTitleCtrl.clear();
      _expenseAmountCtrl.clear();
    });
  }

  void _removeExpense(String id) {
    setState(() {
      _expenses.removeWhere((e) => e.id == id);
    });
  }

  void _reconcileShift(double expectedCash) {
    if (_actualCashCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى عدّ النقدية الفعلية في الدرج أولاً وإدخال المبلغ'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final diff = _actualCash - expectedCash;
    String statusMessage;
    if (diff.abs() < 0.01) {
      statusMessage = 'تم اعتماد تقفيل الوردية: الدرج مطابق تماماً بالمليم! ✅';
    } else if (diff < 0) {
      statusMessage =
          'تم اعتماد تقفيل الوردية مع تسجيل عجز: ${diff.abs().toStringAsFixed(0)} ج.م ⚠️';
    } else {
      statusMessage =
          'تم اعتماد تقفيل الوردية مع تسجيل فائض: +${diff.toStringAsFixed(0)} ج.م ℹ️';
    }

    setState(() => _isClosed = true);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.success),
              SizedBox(width: 8),
              Text('تقرير تقفيل الدرج المعتمد'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Divider(),
              _buildSummaryRow(
                  'العهدة الافتتاحية:', '${_openingFloat.toStringAsFixed(0)} ج.م'),
              _buildSummaryRow(
                  'المصروفات النثرية:', '${_totalExpenses.toStringAsFixed(0)} ج.م'),
              _buildSummaryRow(
                  'المبلغ المتوقع بالدرج:', '${expectedCash.toStringAsFixed(0)} ج.م'),
              _buildSummaryRow(
                  'المبلغ الفعلي بالدرج:', '${_actualCash.toStringAsFixed(0)} ج.م'),
              _buildSummaryRow(
                'الفارق:',
                '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(0)} ج.م',
                color: diff == 0
                    ? AppColors.success
                    : (diff < 0 ? AppColors.danger : AppColors.info),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إرسال التقرير لطباعة إيصال الإغلاق'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.print_rounded, size: 16),
              label: const Text('طباعة التقرير'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            val,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final todayRev = todayRevenueAsync.value ?? 0.0;
    final expectedCash = _openingFloat + todayRev - _totalExpenses;
    final diff = _actualCashCtrl.text.isNotEmpty ? (_actualCash - expectedCash) : null;

    final formattedToday =
        intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Manager Header Banner
          Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'إدارة الخزينة ومطابقة الدرج اليومي',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Manager Tool',
                              style: GoogleFonts.jetBrainsMono(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$formattedToday — مطابقة التحصيل المباشر والنقدية الملموسة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),

          // 4-Card Bento Grid
          LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 800;
              final cards = [
                _buildKpiCard(
                  context,
                  title: 'العهدة الافتتاحية (الدرج)',
                  subtitle: 'النقدية الصباحية / الفكة',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _openingFloatCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Text('ج.م',
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary(context))),
                    ],
                  ),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
                _buildKpiCard(
                  context,
                  title: 'التحصيل الإجمالي اليوم',
                  subtitle: 'كشوفات وخدمات مؤكدة',
                  valueWidget: Text(
                    '${todayRev.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
                _buildKpiCard(
                  context,
                  title: 'المصروفات النثرية',
                  subtitle: '${_expenses.length} بنود صرف مسجلة',
                  valueWidget: Text(
                    '${_totalExpenses.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.danger,
                ),
                _buildKpiCard(
                  context,
                  title: 'الرصيد المتوقع بالدرج',
                  subtitle: 'عهدة + تحصيل - مصروفات',
                  valueWidget: Text(
                    '${expectedCash.toStringAsFixed(0)} ج.م',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  icon: Icons.calculate_outlined,
                  color: const Color(0xFF7C3AED),
                  highlight: true,
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1)
                        const SizedBox(height: AppSpace.md),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1)
                      const SizedBox(width: AppSpace.md),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.xl),

          // Two-Column Work Area: Cash Verification & Petty Expenses
          LayoutBuilder(
            builder: (context, c) {
              final isStacked = c.maxWidth < 900;
              final leftCol = _buildCashVerificationCard(
                  context, expectedCash, diff);
              final rightCol = _buildPettyExpensesCard(context);

              if (isStacked) {
                return Column(
                  children: [
                    leftCol,
                    const SizedBox(height: AppSpace.xl),
                    rightCol,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: leftCol),
                  const SizedBox(width: AppSpace.xl),
                  Expanded(flex: 5, child: rightCol),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget valueWidget,
    required IconData icon,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.08)
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? color.withValues(alpha: 0.4)
              : AppColors.borderSubtle(context),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          valueWidget,
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashVerificationCard(
      BuildContext context, double expectedCash, double? diff) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'العد الفعلي للنقدية ومطابقة الدرج',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'قم بعد النقدية الفعلية داخل الدرج وأدخل المبلغ لمقارنته بالرصيد المسجل',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Input for Actual Cash
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.subtle(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle(context)),
            ),
            child: Row(
              children: [
                Text(
                  'المبلغ الفعلي الموجود:',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _actualCashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثال: 4500',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        color: AppColors.textMuted(context),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      suffixText: 'ج.م',
                      suffixStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Variance Result Indicator
          if (diff != null) ...[
            Builder(
              builder: (context) {
                final isBalanced = diff.abs() < 0.01;
                final isDeficit = !isBalanced && diff < 0;

                final Color bgColor = isBalanced
                    ? AppColors.successSubtle
                    : (isDeficit ? AppColors.dangerSubtle : AppColors.infoSubtle);
                final Color borderColor = isBalanced
                    ? AppColors.success
                    : (isDeficit ? AppColors.danger : AppColors.info);
                final IconData icon = isBalanced
                    ? Icons.check_circle_rounded
                    : (isDeficit
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded);

                final String subtitle = isBalanced
                    ? 'المبلغ الفعلي يطابق الرصيد المحسوب بالمليم.'
                    : (isDeficit
                        ? 'يرجى مراجعة فواتير الكشوفات وسندات الصرف النثري قبل التقفيل.'
                        : 'يوجد فائض في النقدية الفعلية مقارنة بالحركات المسجلة.');

                return Container(
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: borderColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: borderColor,
                                ),
                                children: [
                                  if (isBalanced) ...[
                                    const TextSpan(text: 'الخزينة مطابقة تماماً ('),
                                    TextSpan(
                                      text: '0.00 ج.م',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: ')'),
                                  ] else if (isDeficit) ...[
                                    const TextSpan(text: 'عجز بالدرج ('),
                                    TextSpan(
                                      text: '-${diff.abs().toStringAsFixed(2)} ج.م',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: ')'),
                                  ] else ...[
                                    const TextSpan(text: 'فائض بالدرج ('),
                                    TextSpan(
                                      text: '+${diff.toStringAsFixed(2)} ج.م',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: ')'),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpace.xl),
          ],

          // Reconcile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _reconcileShift(expectedCash),
              icon: const Icon(Icons.lock_clock_rounded),
              label: Text(
                _isClosed ? 'تم اعتماد تقفيل اليوم (إعادة الفحص)' : 'اعتماد تقفيل الدرج واليومية',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isClosed ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPettyExpensesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.outbox_rounded,
                  size: 20, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'المصروفات النثرية من الدرج (Petty Cash)',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'تسجيل أي مبالغ تم سحبها من الدرج اليوم (ضيافة، أدوات نظافة، صيانة)',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Add Expense Form
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: _expenseTitleCtrl,
                  decoration: InputDecoration(
                    hintText: 'سبب الصرف (مثال: مستلزمات نظافة)',
                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.subtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppColors.borderSubtle(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _expenseAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: 'المبلغ (ج.م)',
                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: AppColors.subtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: AppColors.borderSubtle(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),

          // Expenses List
          if (_expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لم يتم تسجيل أي مصروفات نثرية اليوم حتى الآن.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final exp = _expenses[index];
                final timeFormatted =
                    intl.DateFormat('hh:mm a', 'ar').format(exp.time);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.dangerSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove_rounded,
                            size: 14, color: AppColors.danger),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exp.title,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              timeFormatted,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.5,
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-${exp.amount.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => _removeExpense(exp.id),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.lightTextMuted),
                        tooltip: 'حذف البند',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
