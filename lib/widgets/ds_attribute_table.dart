import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ds_panel.dart';
import '../models/player_profile.dart';

class DsAttributeTable extends StatelessWidget {
  final PlayerProfile profile;

  const DsAttributeTable({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return DsPanel(
      child: Column(
        children: [
          // 1. ZÁKLADNÍ ATRIBUTY (Síla, Obratnost atd.)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Síla", "${profile.strMax}"),
                    _buildSFRow("Obratnost", "${profile.dexMax}"),
                    _buildSFRow("Inteligence", "${profile.intMax}"),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Vitalita", "${profile.vitMax}"),
                    _buildSFRow("Štěstí", "${profile.luckMax}"),
                    _buildSFRow("Preciznost", "${profile.precMax}"),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppTheme.panelWood, height: 25),

          // 2. ROZŠÍŘENÉ BOJOVÉ STATISTIKY
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEVÝ SLOUPEC: ÚTOK
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Poškození", "${profile.dmgMin}-${profile.dmgMax}", color: Colors.redAccent),
          const Divider(color: AppTheme.panelWood, height: 25),
                    _buildSFRow("Rychlost útoku", "${profile.attackSpeed}", color: Colors.redAccent),
                    _buildSFRow("Kritická šance", "${profile.critChance} %", color: Colors.redAccent),
                    _buildSFRow("Kritické poškození", "${profile.critMultiplier} x", color: Colors.redAccent),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),

              // PRAVÝ SLOUPEC: OBRANA / ODOLNOSTI
              Expanded(
                child: Column(
                  children: [
                    _buildSFRow("Brnění", "${profile.armor}", color: Colors.blueAccent),
          const Divider(color: AppTheme.panelWood, height: 25),
                    _buildSFRow("Lehká odolnost", "${profile.strResist} %", color: Colors.blueAccent),
                    _buildSFRow("Magická odolnost", "${profile.intResist} %", color: Colors.blueAccent),
                    _buildSFRow("Těžká odolnost", "${profile.dexResist} %", color: Colors.blueAccent),
                  ],
                ),
              ),
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
          Text(
            value, 
            style: TextStyle(
              color: color ?? AppTheme.textLight, 
              fontWeight: FontWeight.bold, 
              fontSize: 14
            )
          ),
        ],
      ),
    );
  }
}