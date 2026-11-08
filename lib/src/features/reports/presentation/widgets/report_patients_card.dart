import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// بطاقة إحصاءات المرضى الجدد والقدامى ونسبتهم
class ReportPatientsCard extends StatelessWidget {
  final bool isDark;
  final int newPatients;
  final int oldPatients;

  const ReportPatientsCard({
    super.key,
    required this.isDark,
    required this.newPatients,
    required this.oldPatients,
  });

  @override
  Widget build(BuildContext context) {
    final total = newPatients + oldPatients;
    const newColor = AppColors.success;
    const oldColor = AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: newColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_alt_outlined,
                    size: 16, color: newColor),
              ),
              const SizedBox(width: 10),
              Text(
                'المرضى',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // بطاقتا المرضى الجدد والقدامى
          Row(
            children: [
              Expanded(
                child: _buildPatientCountCard(
                  context,
                  'مرضى جدد',
                  newPatients,
                  newColor,
                  Icons.fiber_new_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPatientCountCard(
                  context,
                  'مرضى قدامى',
                  oldPatients,
                  oldColor,
                  Icons.person_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // شريط النسبة
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: newPatients / total,
                backgroundColor: oldColor.withValues(alpha: 0.25),
                color: newColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جدد: ${total > 0 ? (newPatients / total * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: newColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'قدامى: ${total > 0 ? (oldPatients / total * 100).toStringAsFixed(0) : 0}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: oldColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientCountCard(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrains Mono',
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
