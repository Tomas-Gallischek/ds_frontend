import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/map_screen.dart';
import '../screens/steps_screen.dart';
import '../screens/blacksmith_screen.dart';

class GameMenu extends StatelessWidget {
  const GameMenu({super.key});

@override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgDark,
      child: Column(
        children: [
          // ... (Hlavička zůstává beze změny) ...
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: AppTheme.panelDark,
              border: Border(bottom: BorderSide(color: AppTheme.panelWood, width: 3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.fort, color: AppTheme.accentGold, size: 50),
                const SizedBox(height: 10),
                Text('DUNGEON STEPS', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppTheme.accentGold, letterSpacing: 2)),
                Text('HLAVNÍ MENU', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, letterSpacing: 4)),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border(right: BorderSide(color: AppTheme.panelWood.withAlpha(100), width: 1))),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildRPGItem(context, 'PROFIL', Icons.person, const ProfileScreen()),
                  _buildRPGItem(context, 'KOVÁRNA', Icons.hardware, const BlacksmithScreen()), // <--- PŘIDÁNO: Tlačítko Kovárny
                  _buildRPGItem(context, 'VÝPRAVA (MAPA)', Icons.map, const MapScreen()),
                  _buildRPGItem(context, 'KROKY HODINY', Icons.directions_run, const StepsScreen()),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(color: AppTheme.panelWood, thickness: 1),
                  ),
                  
                  _buildRPGItem(context, 'ŽEBŘÍČEK', Icons.leaderboard, null),
                  _buildRPGItem(context, 'NASTAVENÍ', Icons.settings, null),
                ],
              ),
            ),
          ),

          // TLAČÍTKO ODHLÁŠENÍ (Sestup na konec menu)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.panelWood, width: 2),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'OPUSTIT HRU',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              onTap: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  // Pomocná funkce pro RPG položku menu
  Widget _buildRPGItem(BuildContext context, String title, IconData icon, Widget? targetScreen) {
    bool isReady = targetScreen != null;

    return ListTile(
      leading: Icon(
        icon,
        color: isReady ? AppTheme.accentGold : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isReady ? AppTheme.textLight : Colors.grey.shade700,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Zavře Drawer
        if (isReady) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tato síň je zatím uzavřena...'),
              backgroundColor: AppTheme.panelDark,
            ),
          );
        }
      },
    );
  }

  // Logika odhlášení
  Future<void> _handleLogout(BuildContext context) async {
    // 1. Smažeme token přes ApiService
    await ApiService().logout();

    // 2. Přesun na LoginScreen a vymazání historie navigace
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}