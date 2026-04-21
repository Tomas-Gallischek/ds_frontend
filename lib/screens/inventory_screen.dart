import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ds_equipment_slot.dart';
import '../models/player_profile.dart'; // Ujisti se, že tento import ukazuje na soubor s BaseItem a EqpItem
import '../services/api_service.dart'; // Ujisti se, že tento import ukazuje na tvůj ApiService

class InventoryScreen extends StatelessWidget {
  final String title;
  final String filterCategory; // 'equip', 'material', 'useable'
  final List<BaseItem> allItems; // Používáme naši novou chytrou třídu

  const InventoryScreen({
    super.key,
    required this.title,
    required this.filterCategory,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context) {
    // MAGIE FILTRACE: Nyní používáme tečkovou notaci (item.category atd.)
    final filteredItems = allItems.where((item) {
      if (item.itemStatus != 'inventory') return false;

      if (filterCategory == 'equip') {
        return ['weapon', 'armor', 'helmet', 'boots', 'amulet', 'ring', 'talisman', 'pet'].contains(item.category);
      } else if (filterCategory == 'material') {
        return ['material', 'quest'].contains(item.category);
      } else if (filterCategory == 'useable') {
        return ['useable'].contains(item.category);
      }
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentGold, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg/bg_dungeon_steps.png'), 
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withAlpha(153), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    "Tady je zatím prázdno, hrdino.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 itemy vedle sebe
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    
                    return GestureDetector(
                      onTap: () => _showItemDetails(context, item), // KLIKNUTÍ OTEVŘE DETAIL
                      child: DsEquipmentSlot(
                        // Ujisti se, že cesta k obrázkům odpovídá tvé složce
                        itemImg: 'assets/items/${item.category == 'weapon' ? 'weapons' : item.category == 'armor' ? 'armor' : 'materials'}/${item.itemImgOzn}.png', 
                        rarity: item.rarity,
                        size: double.infinity, 
                        amount: item.amount,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ==========================================
  // VYSKAKOVACÍ OKNO S DETAILEM PŘEDMĚTU
  // ==========================================
void _showItemDetails(BuildContext context, BaseItem item) {
  bool isProcessing = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.panelDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HLAVIČKA A POPIS (Zkráceno pro přehlednost)
                Row(
                  children: [
                    DsEquipmentSlot(
                      itemImg: 'assets/items/${item.category == 'weapon' ? 'weapons' : item.category == 'armor' ? 'armor' : 'accessories'}/${item.itemImgOzn}.png',
                      rarity: item.rarity,
                      size: 70,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _getRarityColor(item.rarity))),
                          Text('Pož. Úroveň: ${item.lvlReq}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.panelWood, height: 30),

                // STATY (Filtrované)
                if (item is EqpItem) ..._buildItemStats(item),

                const SizedBox(height: 25),

                // AKCE S POJISTKOU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (item is EqpItem)
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing 
                            ? null 
                            : () async {
                                setModalState(() => isProcessing = true);
                                // Voláme nasazení
                                await _equipItem(context, item);
                                // Navigator.pop se děje uvnitř _equipItem
                              },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
                          icon: isProcessing 
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.shield, color: Colors.black),
                          label: Text(
                            isProcessing ? "NASAZUJI..." : "NASADIT", 
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
      );
    }
  );
}

  // ==========================================
  // POMOCNÉ FUNKCE PRO VYKRESLENÍ STATŮ
  // ==========================================
  
  List<Widget> _buildItemStats(BaseItem item) {
    List<Widget> rows = [];

    // Tato chytrá funkce přidá řádek JEN TEHDY, když hodnota existuje a není 0
    void addStat(String label, dynamic value, {Color color = Colors.white, String suffix = ''}) {
      if (value != null && value != 0 && value != '') {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
                Text('$value$suffix', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        );
      }
    }

    // Pokud je to výbava, zkontrolujeme všechny její staty
    if (item is EqpItem) {
      if (item.dmgMin > 0 || item.dmgMax > 0) {
        addStat("Poškození", "${item.dmgMin} - ${item.dmgMax}", color: Colors.redAccent);
      }
      addStat("Průměrné poškození", item.dmgAvg, color: Colors.redAccent);
      addStat("Brnění", item.armor, color: Colors.blueAccent);
      addStat("Životy", item.plusHp, color: Colors.green);
      addStat("Rychlost útoku zbraně", item.attackSpeedWeapon);
      addStat("Bonus k atributům (Amulet)", item.allAtrBonusAmulet, suffix: " ke všem");
      addStat("Bonus k atributům (Prsten)", item.allAtrBonusRing, suffix: " ke všem");
      addStat("Úroveň mazlíčka", item.petLvl);
      addStat("Pet DMG Bonus", item.petDmgBonus);
      addStat("Pet HP Bonus", item.petHpBonus);
      addStat("Pet Armor Bonus", item.petArmorBonus);
    } 
    // Pokud je to materiál
    else if (item is MaterialItem) {
      addStat("Kusů v batohu", item.amount);
    }

    return rows;
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.white; // basic
    }
  }

// --- FUNKCE PRO NASAZENÍ ITEMU ---
  Future<void> _equipItem(BuildContext context, EqpItem item) async {
    // 1. Zobrazíme rychlý vizuální feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nasazuji: ${item.name}...'), duration: const Duration(seconds: 1)),
    );

    final success = await ApiService().toggleEquip(item.itemId!, item.name, 'equipped');
    
    // 3. Počkáme na odpověď a pokud jsme stále na této obrazovce (mounted):
    if (context.mounted) {
      Navigator.pop(context); // Tohle zavře ten spodní vyskakovací panel (Bottom Sheet)
      
      if (success) {
        // Pokud to klaplo, zavřeme i celý inventář a pošleme signál "true" profilu,
        // aby věděl, že se má znovu načíst z databáze a ukázat novou výbavu.
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chyba při nasazování! Zkus to znovu.'), backgroundColor: Colors.red),
        );
      }
    }
  }
}