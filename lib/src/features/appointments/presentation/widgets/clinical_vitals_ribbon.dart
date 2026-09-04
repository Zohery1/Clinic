import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/ui/tokens/colors.dart';

class ClinicalVitalsData {
  String bloodPressure;
  String pulse;
  String temperature;
  String weight;
  String height;
  String bloodGlucose;

  ClinicalVitalsData({
    this.bloodPressure = '',
    this.pulse = '',
    this.temperature = '',
    this.weight = '',
    this.height = '',
    this.bloodGlucose = '',
  });

  double? get bmi {
    final w = double.tryParse(weight);
    final h = double.tryParse(height);
    if (w != null && h != null && h > 0) {
      final hMeters = h > 3 ? h / 100 : h;
      return w / (hMeters * hMeters);
    }
    return null;
  }

  String get bmiCategory {
    final val = bmi;
    if (val == null) return '';
    if (val < 18.5) return 'نحافة';
    if (val < 25) return 'وزن مثالي';
    if (val < 30) return 'زيادة وزن';
    return 'سمنة';
  }

  Color get bmiColor {
    final val = bmi;
    if (val == null) return Colors.grey;
    if (val < 18.5) return Colors.blue;
    if (val < 25) return AppColors.success;
    if (val < 30) return AppColors.warning;
    return AppColors.danger;
  }

  String encode() {
    return 'BP=$bloodPressure;HR=$pulse;T=$temperature;WT=$weight;HT=$height;BG=$bloodGlucose';
  }

  static ClinicalVitalsData decode(String raw) {
    final data = ClinicalVitalsData();
    if (raw.isEmpty) return data;
    final pairs = raw.split(';');
    for (final pair in pairs) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        final k = kv[0].trim().toUpperCase();
        final v = kv[1].trim();
        switch (k) {
          case 'BP':
            data.bloodPressure = v;
            break;
          case 'HR':
            data.pulse = v;
            break;
          case 'T':
            data.temperature = v;
            break;
          case 'WT':
            data.weight = v;
            break;
          case 'HT':
            data.height = v;
            break;
          case 'BG':
            data.bloodGlucose = v;
            break;
        }
      }
    }
    return data;
  }
}

/// شريط المؤشرات الحيوية السريرية (Clinical Vitals Ribbon)
class ClinicalVitalsRibbon extends StatefulWidget {
  final ClinicalVitalsData vitals;
  final ValueChanged<ClinicalVitalsData> onChanged;
  final bool readOnly;

  const ClinicalVitalsRibbon({
    super.key,
    required this.vitals,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<ClinicalVitalsRibbon> createState() => _ClinicalVitalsRibbonState();
}

class _ClinicalVitalsRibbonState extends State<ClinicalVitalsRibbon> {
  late TextEditingController _bpCtrl;
  late TextEditingController _pulseCtrl;
  late TextEditingController _tempCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _sugarCtrl;

  @override
  void initState() {
    super.initState();
    _bpCtrl = TextEditingController(text: widget.vitals.bloodPressure);
    _pulseCtrl = TextEditingController(text: widget.vitals.pulse);
    _tempCtrl = TextEditingController(text: widget.vitals.temperature);
    _weightCtrl = TextEditingController(text: widget.vitals.weight);
    _heightCtrl = TextEditingController(text: widget.vitals.height);
    _sugarCtrl = TextEditingController(text: widget.vitals.bloodGlucose);
  }

  @override
  void didUpdateWidget(covariant ClinicalVitalsRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vitals != oldWidget.vitals) {
      if (_bpCtrl.text != widget.vitals.bloodPressure) {
        _bpCtrl.text = widget.vitals.bloodPressure;
      }
      if (_pulseCtrl.text != widget.vitals.pulse) {
        _pulseCtrl.text = widget.vitals.pulse;
      }
      if (_tempCtrl.text != widget.vitals.temperature) {
        _tempCtrl.text = widget.vitals.temperature;
      }
      if (_weightCtrl.text != widget.vitals.weight) {
        _weightCtrl.text = widget.vitals.weight;
      }
      if (_heightCtrl.text != widget.vitals.height) {
        _heightCtrl.text = widget.vitals.height;
      }
      if (_sugarCtrl.text != widget.vitals.bloodGlucose) {
        _sugarCtrl.text = widget.vitals.bloodGlucose;
      }
    }
  }

  @override
  void dispose() {
    _bpCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _sugarCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.vitals.bloodPressure = _bpCtrl.text.trim();
    widget.vitals.pulse = _pulseCtrl.text.trim();
    widget.vitals.temperature = _tempCtrl.text.trim();
    widget.vitals.weight = _weightCtrl.text.trim();
    widget.vitals.height = _heightCtrl.text.trim();
    widget.vitals.bloodGlucose = _sugarCtrl.text.trim();
    widget.onChanged(widget.vitals);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bmi = widget.vitals.bmi;
    final bmiCat = widget.vitals.bmiCategory;
    final bmiCol = widget.vitals.bmiColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.subtle(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'المؤشرات والعلامات الحيوية (Vitals)',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              if (bmi != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: bmiCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BMI: ${bmi.toStringAsFixed(1)} ($bmiCat)',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: bmiCol,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVitalCell(
                  label: 'ضغط الدم',
                  unit: 'mmHg',
                  hint: '120/80',
                  controller: _bpCtrl,
                  icon: Icons.speed_rounded,
                ),
                const SizedBox(width: 10),
                _buildVitalCell(
                  label: 'النبض',
                  unit: 'bpm',
                  hint: '72',
                  controller: _pulseCtrl,
                  icon: Icons.favorite_border_rounded,
                ),
                const SizedBox(width: 10),
                _buildVitalCell(
                  label: 'الحرارة',
                  unit: '°C',
                  hint: '37.0',
                  controller: _tempCtrl,
                  icon: Icons.thermostat_outlined,
                ),
                const SizedBox(width: 10),
                _buildVitalCell(
                  label: 'الوزن',
                  unit: 'kg',
                  hint: '70',
                  controller: _weightCtrl,
                  icon: Icons.scale_outlined,
                ),
                const SizedBox(width: 10),
                _buildVitalCell(
                  label: 'الطول',
                  unit: 'cm',
                  hint: '170',
                  controller: _heightCtrl,
                  icon: Icons.height_rounded,
                ),
                const SizedBox(width: 10),
                _buildVitalCell(
                  label: 'السكر',
                  unit: 'mg/dL',
                  hint: '110',
                  controller: _sugarCtrl,
                  icon: Icons.water_drop_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCell({
    required String label,
    required String unit,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          TextField(
            controller: controller,
            readOnly: widget.readOnly,
            onChanged: (_) => _notify(),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hint,
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textMuted(context),
              ),
              suffixText: unit,
              suffixStyle: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                color: AppColors.textMuted(context),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
