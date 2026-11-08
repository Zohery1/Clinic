import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/ui/tokens/colors.dart';
import '../../../../../core/ui/tokens/spacing.dart';

/// بطاقة عد النقدية ومطابقة الدرج الفعلي مع حساب الفوارق واعتماد الوردية
class CashVerificationCard extends StatelessWidget {
  final TextEditingController actualCashCtrl;
  final double? diff;
  final bool isClosed;
  final VoidCallback onActualCashChanged;
  final VoidCallback onReconcile;

  const CashVerificationCard({
    super.key,
    required this.actualCashCtrl,
    required this.diff,
    required this.isClosed,
    required this.onActualCashChanged,
    required this.onReconcile,
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
                Icons.fact_check_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'مطابقة النقدية بالدرج',
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
            'أدخل النقدية الفعلية الموجودة بالدرج لمطابقتها بالرصيد الدفتري',
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
                  'النقدية الفعلية:',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: actualCashCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => onActualCashChanged(),
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
                final isBalanced = diff!.abs() < 0.01;
                final isDeficit = !isBalanced && diff! < 0;

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
                    ? 'الرصيد الفعلي يطابق الرصيد الدفتري المسجل.'
                    : (isDeficit
                        ? 'يرجى مراجعة الإيرادات والمصروفات المسجلة قبل التقفيل.'
                        : 'يوجد زيادة في النقدية الفعلية عن الرصيد المسجل.');

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
                                    const TextSpan(
                                      text: 'النقدية مطابقة تماماً (',
                                    ),
                                    TextSpan(
                                      text: '0.00 ج.م',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: ')'),
                                  ] else if (isDeficit) ...[
                                    const TextSpan(text: 'عجز في الخزينة ('),
                                    TextSpan(
                                      text: '-${diff!.abs().toStringAsFixed(2)} ج.م',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(text: ')'),
                                  ] else ...[
                                    const TextSpan(text: 'فائض في الخزينة ('),
                                    TextSpan(
                                      text: '+${diff!.toStringAsFixed(2)} ج.م',
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
              onPressed: onReconcile,
              icon: const Icon(Icons.lock_clock_rounded),
              label: Text(
                isClosed
                    ? 'الوردية مقفلة (إعادة المطابقة)'
                    : 'تقفيل الوردية اليومية',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isClosed ? AppColors.success : AppColors.primary,
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
}
