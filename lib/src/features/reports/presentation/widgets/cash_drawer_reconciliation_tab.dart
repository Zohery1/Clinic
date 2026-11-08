import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../domain/petty_expense_item.dart';
import '../reports_controller.dart';
import 'cash_drawer/cash_drawer_kpi_grid.dart';
import 'cash_drawer/cash_verification_card.dart';
import 'cash_drawer/petty_expenses_card.dart';
import 'cash_drawer/reconciliation_summary_dialog.dart';

export '../../domain/petty_expense_item.dart';

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

    ReconciliationSummaryDialog.show(
      context: context,
      statusMessage: statusMessage,
      openingFloat: _openingFloat,
      totalExpenses: _totalExpenses,
      expectedCash: expectedCash,
      actualCash: _actualCash,
      diff: diff,
      onPrint: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التقرير لطباعة إيصال الإغلاق'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayRevenueAsync = ref.watch(todayRevenueProvider);
    final todayRev = todayRevenueAsync.value ?? 0.0;
    final expectedCash = _openingFloat + todayRev - _totalExpenses;
    final diff =
        _actualCashCtrl.text.isNotEmpty ? (_actualCash - expectedCash) : null;

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
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
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
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Manager Tool',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
          CashDrawerKpiGrid(
            openingFloatCtrl: _openingFloatCtrl,
            todayRev: todayRev,
            totalExpenses: _totalExpenses,
            expensesCount: _expenses.length,
            expectedCash: expectedCash,
            onOpeningFloatChanged: () => setState(() {}),
          ),
          const SizedBox(height: AppSpace.xl),

          // Two-Column Work Area: Cash Verification & Petty Expenses
          LayoutBuilder(
            builder: (context, c) {
              final isStacked = c.maxWidth < 900;
              final leftCol = CashVerificationCard(
                actualCashCtrl: _actualCashCtrl,
                diff: diff,
                isClosed: _isClosed,
                onActualCashChanged: () => setState(() {}),
                onReconcile: () => _reconcileShift(expectedCash),
              );
              final rightCol = PettyExpensesCard(
                expenseTitleCtrl: _expenseTitleCtrl,
                expenseAmountCtrl: _expenseAmountCtrl,
                expenses: _expenses,
                onAddExpense: _addExpense,
                onRemoveExpense: _removeExpense,
              );

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
}
