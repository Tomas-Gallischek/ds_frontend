import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DsStatBar extends StatelessWidget {
  final String label;
  final double progress; // 0.0 až 1.0
  final Color barColor;
  final String valueText;

  const DsStatBar({
    super.key,
    required this.label,
    required this.progress,
    required this.barColor,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(valueText, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.panelWood, width: 1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: barColor.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}