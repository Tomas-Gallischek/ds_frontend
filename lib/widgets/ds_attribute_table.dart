import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ds_panel.dart';

class DsAttributeTable extends StatelessWidget {
  const DsAttributeTable({super.key});

  @override
  Widget build(BuildContext context) {
    return DsPanel(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Síla", "452"),
                    _buildSFRow("Obratnost", "120"),
                    _buildSFRow("Inteligence", "85"),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Vitalita", "380"),
                    _buildSFRow("Štěstí", "154"),
                    _buildSFRow("Preciznost", "92"),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.panelWood, height: 25),
          Row(
            children: [
              Expanded(child: _buildSFRow("Poškození", "210-250", color: Colors.redAccent)),
              const SizedBox(width: 20),
              Expanded(child: _buildSFRow("Brnění", "1.250", color: Colors.blueAccent)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSFRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          Text(value, style: TextStyle(color: color ?? AppTheme.textLight, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}