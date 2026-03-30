import 'package:flutter/material.dart';
import 'package:ds_frontend/screens/profile_screen.dart';
import 'package:ds_frontend/screens/shop_screen.dart';
import 'package:ds_frontend/screens/map_screen.dart';

class GameMenu extends StatelessWidget {
  const GameMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Drawer je ten samotný vysouvací panel
      child: Column(
        children: [
          // Hlavička menu (můžeš si sem později dát logo hry)
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple, // Upravíme podle tvé vizuální identity
            ),
            child: Center(
              child: Text(
                'DUNGEON STEPS',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          // Seznam tlačítek v požadovaném pořadí.
          // Využíváme Expanded a ListView, aby šlo menu scrollovat, pokud se nevejde na menší displej.
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, 'PROFIL', Icons.person, isReady: true),
                _buildMenuItem(context, 'OBCHOD', Icons.store, isReady: true),
                _buildMenuItem(context, 'MAPA', Icons.map, isReady: true),
                _buildMenuItem(context, 'ÚKOLY', Icons.assignment),
                _buildMenuItem(context, 'SCHOPNOSTI', Icons.star),
                _buildMenuItem(context, 'DRUŽINA', Icons.group),
                _buildMenuItem(context, 'ŽEBŘÍČEK', Icons.leaderboard),
                _buildMenuItem(context, 'NASTAVENÍ', Icons.settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pomocná funkce pro vykreslení jednoho řádku v menu
  Widget _buildMenuItem(BuildContext context, String title, IconData icon, {bool isReady = false}) {
    return ListTile(
      leading: Icon(icon, color: isReady ? Colors.deepPurple : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isReady ? Colors.black : Colors.grey, 
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    onTap: () {
        Navigator.pop(context); // Zavře šuplík

        if (isReady) {
          if (title == 'PROFIL') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          } else if (title == 'OBCHOD') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ShopScreen()));
          } else if (title == 'MAPA') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MapScreen())); // Nový přesun!
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Obrazovka $title se zatím připravuje!'), duration: const Duration(seconds: 1)),
          );
        }
      },
    );
  }
}