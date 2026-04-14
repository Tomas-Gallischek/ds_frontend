import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_menu.dart';
import '../widgets/ds_top_bar.dart';
import '../widgets/ds_equipment_slot.dart';
import '../widgets/ds_attribute_table.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    // Definujeme pevnou, "referenční" velikost, kterou FittedBox automaticky naporcuje dle displeje
    const double itemSize = 85.0; 
    
    return Scaffold(
      appBar: const DsTopBar(
        username: "Gallis",
        level: 12,
        gold: 1540,
        dungeonTokens: 2,
        xpProgress: 0.65, 
        avatarImg: 'assets/profile/avatar_default.png',
      ),
      endDrawer: const GameMenu(),
      body: Stack(
        children: [
          // 1. Pozadí
          Positioned.fill(
            child: Image.asset(
              'assets/bg/bg_dungeon_steps.png', // Uprav cestu dle svého
              fit: BoxFit.cover,
              color: Colors.black.withAlpha(153), // 0.6 opacity
              colorBlendMode: BlendMode.darken,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // JMÉNO HRÁČE
                        Text(
                          "GALLIS", 
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        
                        // HP a MANA
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 18),
                            const SizedBox(width: 5),
                            const Text("1.250", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 25),
                            const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                            const SizedBox(width: 5),
                            const Text("450", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // --- SKÁLOVATELNÝ INVENTÁRNÍ KŘÍŽ (U-Layout) ZDE ZMĚNA ---
                        // fittedBox vezme celý tento kontejner a smrskne ho dle šířky displeje
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: FittedBox(
                            fit: BoxFit.contain, // Contain zajistí, že se smrskne na šířku
                            child: SizedBox(
                              // Celková referenční šířka = 4x itemSize (včetně těch spodních rohů)
                              width: itemSize * 4, 
                              height: itemSize * 3, // Výška = 3x itemSize
                              child: Stack(
                                children: [
                                  // LEVÝ SLOUPEC (3 itemy: Helma, Brnění, Boty)
                                  const Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Column(
                                      children: [
                                        DsEquipmentSlot(rarity: 'basic', size: itemSize),
                                        DsEquipmentSlot(itemImg: 'assets/items/armor/kosile.png', rarity: 'basic', size: itemSize),
                                        DsEquipmentSlot(rarity: 'basic', size: itemSize), // Boty (Roh)
                                      ],
                                    ),
                                  ),
                                  
                                  // PRAVÝ SLOUPEC (3 itemy: Amulet, Prsten, Pet)
                                  const Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Column(
                                      children: [
                                        DsEquipmentSlot(rarity: 'epic', size: itemSize),
                                        DsEquipmentSlot(rarity: 'legendary', size: itemSize),
                                        DsEquipmentSlot(rarity: 'rare', size: itemSize), // Pet (Roh)
                                      ],
                                    ),
                                  ),

                                  // CENTRÁLNÍ ČÁST (Profilovka 2x2 + Spodní 2 itemy)
                                  Positioned(
                                    left: itemSize, // Odsazeno o 1 item zleva
                                    top: 0,
                                    child: SizedBox(
                                      width: itemSize * 2,
                                      height: itemSize * 3,
                                      child: Column(
                                        children: [
                                          // Centrální Profilovka (2x2 itemSize)
                                          Container(
                                            width: itemSize * 2,
                                            height: itemSize * 2,
                                            decoration: BoxDecoration(
                                              color: AppTheme.panelDark,
                                              border: Border.all(color: AppTheme.panelWood, width: 3),
                                              image: const DecorationImage(
                                                image: AssetImage('assets/profile/avatar_default.png'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          // Spodní řada pod profilovkou (Zbraň, Talisman)
                                          const Row(
                                            mainAxisSize: MainAxisSize.min, // Zabraňuje roztahování
                                            children: [
                                              DsEquipmentSlot(itemImg: 'assets/items/weapons/rezavy_nuz.png', rarity: 'rare', size: itemSize),
                                              DsEquipmentSlot(rarity: 'basic', size: itemSize),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // TABULKA ATRIBUTŮ (Škálovatelná)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: DsAttributeTable(),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // SPODNÍ TLAČÍTKA INVENTÁŘE
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(127), // 0.5 opacity
                    border: const Border(top: BorderSide(color: AppTheme.panelWood, width: 2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMenuBtn(Icons.shield, "Vybavení"),
                      _buildMenuBtn(Icons.auto_fix_high, "Materiály"),
                      _buildMenuBtn(Icons.healing, "Spotřební"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppTheme.accentGold),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}