import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DsTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final int level;
  final int gold;
  final int dungeonTokens;
  final String avatarImg;
  final double xpProgress; // <-- Zde je náš chybějící parametr!

  const DsTopBar({
    super.key,
    required this.username,
    required this.level,
    required this.gold,
    required this.dungeonTokens,
    required this.xpProgress, // <-- Zde ho vyžadujeme
    this.avatarImg = 'assets/profile/avatar_default.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panelDark.withAlpha(242), // 0.95 opacity
        border: const Border(bottom: BorderSide(color: AppTheme.panelWood, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(127), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              // 1. Profilovka
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGold, width: 2),
                  image: DecorationImage(image: AssetImage(avatarImg), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Jméno a Level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.accentGold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Lvl. $level",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // 3. XP BAR + MĚNY
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tenký XP Bar
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("XP", style: TextStyle(fontSize: 10, color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppTheme.panelWood, width: 0.5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: xpProgress.clamp(0.0, 1.0),
                            child: Container(decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(3))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    _buildCurrency(context, Icons.monetization_on, gold.toString(), Colors.amber),
                    const SizedBox(width: 10),
                    _buildCurrency(context, Icons.vpn_key, dungeonTokens.toString(), Colors.purpleAccent),
                  ],
                ),
              ),

              // 4. Menu tlačítko
              IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.textLight, size: 28),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrency(BuildContext context, IconData icon, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(65.0);
}