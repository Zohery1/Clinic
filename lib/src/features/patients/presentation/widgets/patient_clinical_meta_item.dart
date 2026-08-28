import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// بطاقة عرض معلومة سريرية مختصرة (رقم الهاتف، العنوان، العمر، رقم الملف)
class PatientClinicalMetaItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool useExpanded;
  final VoidCallback? onActionTap;
  final IconData? actionIcon;
  final Color? actionColor;
  final String? actionTooltip;

  const PatientClinicalMetaItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.useExpanded = true,
    this.onActionTap,
    this.actionIcon,
    this.actionColor,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onActionTap != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: actionTooltip ?? '',
                        child: InkWell(
                          onTap: onActionTap,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (actionColor ?? AppTheme.success).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              actionIcon ?? Icons.chat_bubble_outline_rounded,
                              color: actionColor ?? AppTheme.success,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (useExpanded) {
      return Expanded(child: content);
    }
    return content;
  }
}
