import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_menu.dart';
import '../widgets/ds_equipment_slot.dart';
import '../services/api_service.dart';
import '../models/player_profile.dart';

class BlacksmithScreen extends StatefulWidget {
  const BlacksmithScreen({super.key});
  
  @override
  State<BlacksmithScreen> createState() => _BlacksmithScreenState();
}

class _BlacksmithScreenState extends State<BlacksmithScreen> {
  PlayerProfile? _profile;
  List<Map<String, dynamic>> _recipes = []; // Zde budou uloženy všechny recepty
  bool _isLoading = true;
  
  EqpItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  // Načteme profil i recepty SOUČASNĚ
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Čekáme, až se stáhnou obě věci najednou pro větší rychlost
    final results = await Future.wait([
      ApiService().getPlayerProfile(),
      ApiService().getUpgradeRecipes(),
    ]);

    if (mounted) {
      setState(() {
        _profile = results[0] as PlayerProfile?;
        _recipes = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  // --- ZÍSKÁNÍ RECEPTU PRO VYBRANÝ ITEM ---
  Map<String, dynamic>? _getCurrentRecipe(EqpItem item) {
    try {
      // Hledáme recept pro správný typ itemu a na level (aktuální + 1)
      return _recipes.firstWhere((r) => 
        r['item_base_id'] == item.itemBaseId && 
        r['target_lvl'] == item.itemLvl + 1
      );
    } catch (e) {
      return null; // Nenašlo to = item je na max levelu, nebo recept neexistuje
    }
  }

  // --- KOLIK TOHOTO MATERIÁLU MÁ HRÁČ V BATOHU? ---
  int _getPlayerMaterialAmount(int materialBaseId) {
    if (_profile == null) return 0;
    try {
      final mat = _profile!.materialItems.firstWhere((m) => m.itemBaseId == materialBaseId);
      return mat.amount;
    } catch (e) {
      return 0; // Pokud materiál vůbec nemá v batohu
    }
  }

  String _getImgPath(BaseItem item) {
    if (item is MaterialItem) {
      return 'assets/items/materials/${item.itemImgOzn}.png';
    }
    
    String folder = 'accessories';
    if (item.category == 'weapon') {
      folder = 'weapons';
    } else if (['armor', 'helmet', 'boots'].contains(item.category)) {
      folder = 'armor';
    }
    return 'assets/items/$folder/${item.itemImgOzn}.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KOVÁRNA", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold, letterSpacing: 2)),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentGold),
      ),
      endDrawer: const GameMenu(),
      body: _isLoading || _profile == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
          : Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/bg/bg_dungeon_steps.png',
                          fit: BoxFit.cover,
                          color: Colors.black.withAlpha(200),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("K vylepšení", Icons.hardware),
                            _buildItemsGrid(_profile!.eqpItems, isEquip: true),
                            const SizedBox(height: 10),
                            _buildSectionHeader("Sklad Surovin", Icons.diamond),
                            _buildItemsGrid(_profile!.materialItems, isEquip: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 4, color: AppTheme.panelWood),
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withAlpha(230),
                    child: _selectedItem == null 
                      ? _buildEmptyForge() 
                      : _buildActiveForge(_selectedItem!),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyForge() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.handyman, color: Colors.grey, size: 50),
        SizedBox(height: 10),
        Text("VYBER PŘEDMĚT K VYLEPŠENÍ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }

Widget _buildActiveForge(EqpItem item) {
    // 1. Získáme recept
    final recipe = _getCurrentRecipe(item);
    
    // 2. Ošetření, pokud už předmět nejde vylepšit
    if (recipe == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DsEquipmentSlot(itemImg: _getImgPath(item), rarity: item.rarity, size: 70),
          const SizedBox(height: 15),
          const Text("TENTO PŘEDMĚT JIŽ NELZE VYLEPŠIT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      );
    }

    // --- TADY JE TO KOUZLO: TAHÁME KOEFICIENT Z RECEPTU, NE Z ITEMU ---
    final double dmgKoef = (recipe['weapon_dmg_up_koef'] as num?)?.toDouble() ?? 0.0;
    
    // Výpočet nových statů
    final int nextMin = (item.dmgMin * (1 + dmgKoef)).round();
    final int nextMax = (item.dmgMax * (1 + dmgKoef)).round();

    // 3. Vykreslení konkrétního receptu
    final int goldCost = recipe['gold_cost'] ?? 0;
    final int chance = ((recipe['chance'] ?? 0.0) * 100).toInt(); // 0.95 -> 95
    final List<dynamic> requiredMaterials = recipe['materials'] ?? [];

    // Zjistíme, jestli má hráč dostatek všeho (surovin i zlaťáků)
    bool hasEnoughGold = _profile!.gold >= goldCost;
    bool hasAllMaterials = true;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  DsEquipmentSlot(itemImg: _getImgPath(item), rarity: item.rarity, size: 90),
                  const SizedBox(height: 8),
                  // POUŽIJEME dmgKoef z receptu pro zobrazení procent
                  Text("Vylepšení na: +${item.itemLvl + 1}", 
                    style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NÁHLED VYLEPŠENÍ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    
                    // ZOBRAZÍME REÁLNÝ VÝPOČET POŠKOZENÍ (jen u zbraní)
                    if (item.category == 'weapon')
                      Row(
                        children: [
                          Text("Poškození: ${item.dmgMin}-${item.dmgMax}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.green, size: 14),
                          const SizedBox(width: 8),
                          Text("$nextMin-$nextMax", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      
                    // (Volitelně si sem můžeš pak přidat i brnění)
                    if (item.armor > 0)
                      Row(
                        children: [
                          Text("Brnění: ${item.armor}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.green, size: 14),
                          const SizedBox(width: 8),
                          Text("${(item.armor * (1 + dmgKoef)).round()}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),

          // DYNAMICKÉ MATERIÁLY (Tato část zůstává stejná)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: requiredMaterials.map((mat) {
                int needed = mat['amount'];
                int owned = _getPlayerMaterialAmount(mat['material_base_id']);
                bool enough = owned >= needed;
                
                if (!enough) hasAllMaterials = false;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Column(
                    children: [
                      DsEquipmentSlot(itemImg: 'assets/items/materials/${mat['item_img_ozn']}.png', rarity: 'basic', size: 50),
                      const SizedBox(height: 4),
                      Text("$owned / $needed", style: TextStyle(color: enough ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 15),

          // INFO A TLAČÍTKO (Tato část zůstává stejná)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ŠANCE: $chance%", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  Text("CENA: $goldCost G", style: TextStyle(color: hasEnoughGold ? Colors.amber : Colors.red, fontWeight: hasEnoughGold ? FontWeight.normal : FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: (hasEnoughGold && hasAllMaterials) 
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vylepšuji...')));
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("VYLEPŠIT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsGrid(List<BaseItem> items, {required bool isEquip}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isSelected = _selectedItem?.itemId == (item is EqpItem ? item.itemId : -1);

        return GestureDetector(
          onTap: () {
            if (isEquip) {
              setState(() => _selectedItem = item as EqpItem);
            }
          },
          child: Container(
            decoration: isSelected ? BoxDecoration(
              border: Border.all(color: AppTheme.accentGold, width: 2),
              borderRadius: BorderRadius.circular(8),
            ) : null,
            child: Stack(
              children: [
                DsEquipmentSlot(itemImg: _getImgPath(item), rarity: item.rarity, size: double.infinity, amount: item.amount),
                // Zobrazíme u ikony aktuální level itemu (např. +1)
                if (isEquip)
                  Positioned(
                    top: 2, left: 4,
                    child: Text("+${item.itemLvl}", style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 20),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}