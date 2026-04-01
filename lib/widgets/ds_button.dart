import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DsButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary; 

  const DsButton({
    super.key, // <-- Změna zde: super parametr
    required this.text, 
    required this.onPressed, 
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.panelDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? AppTheme.accentGold : AppTheme.panelWood, 
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54, 
              offset: Offset(0, 4), 
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isPrimary ? AppTheme.accentGold : AppTheme.textLight,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}