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
        minScale: 0.1, // Jak moc může hráč mapu oddálit (zmenšit)
        maxScale: 1.0, // Jak moc může hráč mapu přiblížit (zvětšit)
        
        // Stack nám umožní později pokládat ikony lokací přesně na obrázek
child: Stack(
          children: [
            // 1. VRSTVA: Samotné pozadí mapy (tvůj oceán)
            Image.asset(
              'assets/maps/zakladni_tabor.png',
              fit: BoxFit.none, 
            ),
            
            // 2. VRSTVA: Náš první dungeon
            Positioned(
              top: 800,  // Osa Y: Vzdálenost od horního okraje mapy v pixelech
              left: 2075, // Osa X: Vzdálenost od levého okraje mapy v pixelech
              
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
                      // OPRAVA 2: Vynucená velikost ikony, aby se vešla do kolečka
                      child: Image.asset(
                        'assets/maps/dungeon_icons/temny_hvozd_icon.png',
                        width: 200,  // Uprav velikost podle potřeby
                        height: 200, // Uprav velikost podle potřeby
                        fit: BoxFit.contain, // Contain zajistí, že se obrázek smrskne/zvětší tak, aby byl celý vidět
                        opacity: const AlwaysStoppedAnimation(0.7), // Můžeme přidat trochu průhlednosti pro lepší vizuální efekt
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