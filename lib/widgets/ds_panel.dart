import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DsPanel({
    super.key, // <-- Změna zde: super parametr místo : super(key: key)
    required this.child, 
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.panelDark.withValues(alpha: 0.95), // <-- Změna zde: withValues místo withOpacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.panelWood, width: 3), // Dřevěný rám
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7), // <-- Změna zde: withValues místo withOpacity
            blurRadius: 10, 
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}