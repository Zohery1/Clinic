import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';
import '../../../../core/ui/tokens/spacing.dart';
import '../../../appointments/data/visit_note_repository.dart';
import '../../../appointments/domain/visit_note_model.dart';
import '../../../appointments/presentation/widgets/clinical_vitals_ribbon.dart';
import '../../domain/patient_model.dart';

/// Pediatric growth chart: weight and height recorded per visit, plotted
/// against age in months from the patient's birth date. Reads the vitals part
/// of stored visit notes (segment index 3 of the 4-part note format), so no
/// schema change is needed. Hidden unless the patient is under 16.
class PediatricGrowthCard extends ConsumerWidget {
  final PatientModel patient;

  const PediatricGrowthCard({super.key, required this.patient});

  static const int _maxAgeMonths = 191;

  double? _fractionalAgeMonths(DateTime birth, DateTime at) {
    if (birth.isAfter(at)) return null;
    return (at.difference(birth).inDays / 30.4375).clamp(0.0, _maxAgeMonths.toDouble());
  }

  List<_GrowthPoint> _points(List<VisitNoteModel> notes) {
    final birth = patient.birthDate;
    if (birth == null) return const [];
    final out = <_GrowthPoint>[];
    for (final note in notes) {
      final segments = note.notes.split('\n---\n');
      final vitals = segments.length > 3
          ? ClinicalVitalsData.decode(segments[3].trim())
          : ClinicalVitalsData();
      final w = double.tryParse(vitals.weight);
      final h = double.tryParse(vitals.height);
      if (w == null && h == null) continue;
      final age = _fractionalAgeMonths(birth, note.createdAt);
      if (age == null) continue;
      out.add(_GrowthPoint(note.createdAt, age, w, h));
    }
    out.sort((a, b) => a.ageMonths.compareTo(b.ageMonths));
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageMonths = patient.birthDate == null
        ? null
        : _fractionalAgeMonths(patient.birthDate!, DateTime.now());
    final isPediatric = ageMonths != null && ageMonths < 16 * 12;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: AppColors.borderSubtle(context)),
      ),
      color: AppColors.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'منحنى النمو (الوزن والطول مقابل العمر)',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const Spacer(),
                if (!isPediatric)
                  Text(
                    'لا يظهر إلا لمرضى أقل من 16 عاماً',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textMuted(context),
                    ),
                  ),
              ],
            ),
            if (isPediatric) ...[
              const SizedBox(height: AppSpace.sm),
              ref.watch(patientVisitNotesProvider(patient.id)).when(
                    data: (notes) {
                      final points = _points(notes);
                      if (points.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Text(
                                  'تظهر نقطة على المنحنى عند كل زيارة تسجل فيها الوزن والطول.',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textMuted(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              const Row(
                                children: [
                                  Expanded(child: _GrowthMiniChart(points: [], isWeight: true)),
                                  SizedBox(width: AppSpace.sm),
                                  Expanded(child: _GrowthMiniChart(points: [], isWeight: false)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: _GrowthMiniChart(points: points, isWeight: true)),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(child: _GrowthMiniChart(points: points, isWeight: false)),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Text(
                        'تعذر تحميل قياسات النمو.',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrowthPoint {
  final DateTime date;
  final double ageMonths;
  final double? weightKg;
  final double? heightCm;

  const _GrowthPoint(this.date, this.ageMonths, this.weightKg, this.heightCm);
}

class _GrowthMiniChart extends StatelessWidget {
  final List<_GrowthPoint> points;
  final bool isWeight;

  const _GrowthMiniChart({required this.points, required this.isWeight});

  @override
  Widget build(BuildContext context) {
    final color = isWeight ? AppColors.accent(context) : AppColors.successBright;
    final spots = points
        .map((p) => isWeight ? p.weightKg : p.heightCm)
        .whereType<double>()
        .toList();

    final double maxY = isWeight
        ? (spots.isEmpty ? 20 : spots.reduce((a, b) => a > b ? a : b) * 1.2)
        : (spots.isEmpty ? 180 : spots.reduce((a, b) => a > b ? a : b) * 1.15);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isWeight ? 'الوزن (كجم)' : 'الطول (سم)',
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 96,
            child: spots.isEmpty
                ? Center(
                    child: Icon(
                      isWeight ? Icons.monitor_weight_outlined : Icons.height_rounded,
                      size: 26,
                      color: AppColors.textMuted(context),
                    ),
                  )
                : LineChart(_chartData(color, spots, maxY, context)),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(Color color, List<double> weights, double maxY, BuildContext context) {
    final maxX = points.last.ageMonths;
    return LineChartData(
      minY: 0,
      maxY: maxY,
      maxX: maxX <= 0 ? 1 : maxX,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) =>
              AppColors.isDark(context) ? AppColors.darkElevated : AppColors.primaryInk,
          getTooltipItems: (touched) => touched.map((s) {
            final value = s.y.toStringAsFixed(isWeight ? 1 : 0);
            final age = s.x.toInt() < 24
                ? '${s.x.toInt()} شهر'
                : '${(s.x / 12).toStringAsFixed(1)} سنة';
            return LineTooltipItem(
              '$value ${isWeight ? 'كجم' : 'سم'} · $age',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (final p in points)
              if ((isWeight ? p.weightKg : p.heightCm) != null)
                FlSpot(p.ageMonths, isWeight ? p.weightKg! : p.heightCm!),
          ],
          isCurved: true,
          preventCurveOverShooting: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2.2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}
