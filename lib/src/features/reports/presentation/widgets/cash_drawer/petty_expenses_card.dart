import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';
import '../../../domain/petty_expense_item.dart';

/// بطاقة تسجيل واستعراض المصروفات النثرية المسحوبة من الدرج (Petty Cash Card)
class PettyExpensesCard extends StatelessWidget {
  final TextEditingController expenseTitleCtrl;
  final TextEditingController expenseAmountCtrl;
  final List<PettyExpenseItem> expenses;
  final VoidCallback onAddExpense;
  final ValueChanged<String> onRemoveExpense;

  const PettyExpensesCard({
    super.key,
    required this.expenseTitleCtrl,
    required this.expenseAmountCtrl,
    required this.expenses,
    required this.onAddExpense,
    required this.onRemoveExpense,
  });

  @override
  Widget build(BuildContext context) {
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
              const Icon(
                Icons.outbox_rounded,
                size: 20,
                color: AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                'المصروفات النثرية للخزينة',
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
            'تسجيل المصروفات النقدية المسحوبة من الخزينة خلال وردية اليوم.',
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
                  controller: expenseTitleCtrl,
                  decoration: InputDecoration(
                    hintText: 'سبب الصرف (مثال: مستلزمات نظافة)',
                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.subtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderSubtle(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: expenseAmountCtrl,
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
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: AppColors.subtle(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.borderSubtle(context),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAddExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
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
          if (expenses.isEmpty)
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
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final exp = expenses[index];
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
                        child: const Icon(
                          Icons.remove_rounded,
                          size: 14,
                          color: AppColors.danger,
                        ),
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
                        onPressed: () => onRemoveExpense(exp.id),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.lightTextMuted,
                        ),
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
