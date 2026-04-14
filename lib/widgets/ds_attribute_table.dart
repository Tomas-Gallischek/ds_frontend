import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ds_panel.dart';
import '../models/player_profile.dart'; // Přidán import tvého modelu

class DsAttributeTable extends StatelessWidget {
  final PlayerProfile profile; // Nyní tabulka vyžaduje data hráče

  const DsAttributeTable({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return DsPanel(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEVÝ SLOUPEC: Zobrazujeme skutečné hodnoty z databáze
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Síla", "${profile.strength}"),
                    _buildSFRow("Obratnost", "${profile.dexterity}"),
                    _buildSFRow("Inteligence", "${profile.intelligence}"),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // PRAVÝ SLOUPEC
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Vitalita", "${profile.vitality}"),
                    _buildSFRow("Štěstí", "${profile.luck}"),
                    _buildSFRow("Preciznost", "${profile.precision}"),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.panelWood, height: 25),
          // BOJOVÉ STATISTIKY
          Row(
            children: [
              Expanded(child: _buildSFRow("Poškození", "${profile.dmgMin}-${profile.dmgMax}", color: Colors.redAccent)),
              const SizedBox(width: 20),
              Expanded(child: _buildSFRow("Brnění", "${profile.armor}", color: Colors.blueAccent)),
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