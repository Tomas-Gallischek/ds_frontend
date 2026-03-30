import 'package:flutter/material.dart';
import 'package:ds_frontend/widgets/game_menu.dart'; // Náš postranní panel
import 'package:ds_frontend/screens/dungeon_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Světa'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              child: const Text('MENU', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      endDrawer: const GameMenu(), // Přístup do menu zachován
      
      // InteractiveViewer se postará o veškeré posouvání a přibližování
      body: InteractiveViewer(
        constrained: false, // DŮLEŽITÉ: Dovolí mapě přetéct přes okraje obrazovky
        boundaryMargin: EdgeInsets.zero, // Zabrání hráči odscrollovat úplně mimo mapu do prázdna
        minScale: 0.5, // Jak moc může hráč mapu oddálit (zmenšit)
        maxScale: 3.0, // Jak moc může hráč mapu přiblížit (zvětšit)
        
        // Stack nám umožní později pokládat ikony lokací přesně na obrázek
child: Stack(
          children: [
            // 1. VRSTVA: Samotné pozadí mapy (tvůj oceán)
            Image.asset(
              'assets/map_background.png',
              fit: BoxFit.none, 
            ),
            
            // 2. VRSTVA: Náš první dungeon
            Positioned(
              top: 400,  // Osa Y: Vzdálenost od horního okraje mapy v pixelech
              left: 300, // Osa X: Vzdálenost od levého okraje mapy v pixelech
              
              // GestureDetector zachytává dotyky prstem na mapě
              child: GestureDetector(
                onTap: () {
                  // Otevřeme DungeonScreen a předáme mu ID 1
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DungeonScreen(dungeonId: 1),
                    ),
                  );
                },
                
                // Samotný vizuál bodu na mapě
                child: Column(
                  children: [
                    // Zde používám zabudovanou ikonku, ale později sem můžeš 
                    // dát zase Image.asset('assets/ikona_dungeonu.png')
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(), // Poloprůhledný černý podklad pro lepší viditelnost
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent, width: 2),
                      ),
                      child: const Icon(Icons.castle, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(height: 4),
                    
                    // Jmenovka lokace s lehkým podkladem pro lepší čitelnost
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: Colors.black54,
                      child: const Text(
                        'Opuštěná pevnost',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}