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
  List<Map<String, dynamic>> _recipes = []; 
  bool _isLoading = true;
  bool _isUpgrading = false; // <--- PŘIDÁNO: Zámek proti spamu
  
  EqpItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
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

  Map<String, dynamic>? _getCurrentRecipe(EqpItem item) {
    try {
      return _recipes.firstWhere((r) => 
        r['item_base_id'] == item.itemBaseId && 
        r['target_lvl'] == item.itemLvl + 1
      );
    } catch (e) {
      return null;
    }
  }

  int _getPlayerMaterialAmount(int materialBaseId) {
    if (_profile == null) return 0;
    try {
      final mat = _profile!.materialItems.firstWhere((m) => m.itemBaseId == materialBaseId);
      return mat.amount;
    } catch (e) {
      return 0; 
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

  // --- POMOCNÝ WIDGET PRO VYKRESLENÍ JEDNOHO ŘÁDKU STATŮ ---
  Widget _buildStatPreview(String label, String current, String next) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text("$label: $current", style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Text(next, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  // --- GENEROVÁNÍ NÁHLEDŮ PODLE KATEGORIE ---
List<Widget> _generatePreviewStats(EqpItem item) {
    List<Widget> stats = [];
    debugPrint("Generuji náhled pro ${item.category} s itemLvl ${item.itemLvl} a koeficientem ${item.weaponDmgUpKoef}");
    if (item.category == 'weapon') {
      // ZMĚNĚNO NA .ceil()
      int nextMin = (item.dmgMin * (1 + item.weaponDmgUpKoef)).ceil();
      int nextMax = (item.dmgMax * (1 + item.weaponDmgUpKoef)).ceil();
      stats.add(_buildStatPreview("Poškození", "${item.dmgMin}-${item.dmgMax}", "$nextMin-$nextMax"));
    } 
    else if (item.category == 'armor') {
      // ZMĚNĚNO NA .ceil()
      int nextArmor = (item.armor * (1 + item.armorArmorUpKoef)).ceil();
      int nextHp = (item.plusHp * (1 + item.armorHpUpKoef)).ceil();
      stats.add(_buildStatPreview("Brnění", "${item.armor}", "$nextArmor"));
      if (item.plusHp > 0 || nextHp > 0) {
        stats.add(_buildStatPreview("Zdraví", "${item.plusHp}", "$nextHp"));
      }
    } 
    else if (item.category == 'helmet') {
      // ZMĚNĚNO NA .ceil()
      int nextArmor = (item.armor * (1 + item.helmetArmorUpKoef)).ceil();
      stats.add(_buildStatPreview("Brnění", "${item.armor}", "$nextArmor"));
    } 
    else if (item.category == 'boots') {
      // ZMĚNĚNO NA .ceil()
      int nextArmor = (item.armor * (1 + item.bootsArmorUpKoef)).ceil();
      double nextAs = item.attackSpeedBoots + item.bootsAttackSpeedUpKoef; // Sčítání zůstává
      stats.add(_buildStatPreview("Brnění", "${item.armor}", "$nextArmor"));
      if (item.attackSpeedBoots > 0 || nextAs > 0) {
        stats.add(_buildStatPreview("Rychlost útoku", "${item.attackSpeedBoots}", nextAs.toStringAsFixed(2)));
      }
    } 
    else if (item.category == 'amulet') {
      int currentAtr = item.allAtrBonusAmulet ?? 0;
      // ZMĚNĚNO NA .ceil()
      int nextAtr = currentAtr + item.amuletAtrUpKoef.ceil(); 
      stats.add(_buildStatPreview("Všechny Atributy", "$currentAtr", "$nextAtr"));
    } 
    else if (item.category == 'ring') {
      int currentAtr = item.allAtrBonusRing ?? 0;
      // ZMĚNĚNO NA .ceil()
      int nextAtr = currentAtr + item.ringAtrUpKoef.ceil();
      stats.add(_buildStatPreview("Všechny Atributy", "$currentAtr", "$nextAtr"));
    }

    return stats;
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
    final recipe = _getCurrentRecipe(item);
    
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

    final int goldCost = recipe['gold_cost'] ?? 0;
    final int chance = ((recipe['chance'] ?? 0.0) * 100).toInt(); 
    final List<dynamic> requiredMaterials = recipe['materials'] ?? [];

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
                    
                    // --- ZDE VOLÁME NAŠI NOVOU GENERUJÍCÍ FUNKCI ---
                    ..._generatePreviewStats(item),
                    
                  ],
                ),
              ),
            ],
          ),
          
          const Spacer(),

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
                // Tlačítko je aktivní, jen pokud máš zlato, materiály a ZÁROVEŇ zrovna neprobíhá vylepšování
                onPressed: (hasEnoughGold && hasAllMaterials && !_isUpgrading) 
                  ? () async {
                      // 1. Zamkneme tlačítko
                      setState(() => _isUpgrading = true);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kovám předmět... 🔨'), duration: Duration(seconds: 1)),
                      );

                      // 2. Zavoláme API (pozor, používáme itemId, ne itemBaseId)
                      bool success = await ApiService().upgradeItem(item.itemId!, item.itemBaseId!);

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vylepšení úspěšné (OPRAVIT - UKAZUJE SE I PŘI NEZDARU! 🎉'), backgroundColor: Colors.green),
                        );
                        
                        // 3. Stáhneme nová data (profil i recepty)
                        await _fetchData();
                        
                        // 4. Přelinkujeme vybraný předmět, aby se rovnou ukázaly nové staty!
                        if (_profile != null && mounted) {
                          setState(() {
                            try {
                              _selectedItem = _profile!.eqpItems.firstWhere((e) => e.itemId == item.itemId);
                            } catch (e) {
                              _selectedItem = null; // Kdyby se něco pokazilo, vyprázdníme kovadlinu
                            }
                          });
                        }
                      } else if (mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chyba při vylepšování! Zkus to znovu.'), backgroundColor: Colors.red),
                        );
                      }

                      // 5. Odemkneme tlačítko
                      if (mounted) {
                        setState(() => _isUpgrading = false);
                      }
                    }
                  : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                // Zobrazíme buď text, nebo kolečko načítání, pokud se zrovna kove
                child: _isUpgrading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("VYLEPŠIT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildItemsGrid(List<BaseItem> items, {required bool isEquip}) {
    // TOTO ZABRÁNÍ TEMNÉMU PRÁZDNÉMU MÍSTU, KDYŽ SE NIC NENAČTE
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            isEquip ? "Žádné vybavení nenalezeno." : "Sklad surovin je prázdný.", 
            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)
          ),
        ),
      );
    }

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
          // TATO VLASTNOST ZAJISTÍ, ŽE FUNGUJE KLIK I DO "PRŮHLEDNÉHO" PRÁZDNA
          behavior: HitTestBehavior.translucent, 
          
          onTap: () {
            if (isEquip) {
              debugPrint("=== KLIKNUTÍ NA ITEM ===");
              debugPrint("1. Item: ${item.name} | Lvl: ${item.itemLvl}");
              debugPrint("2. Koeficient zbraně: ${(item as EqpItem).weaponDmgUpKoef}");
              debugPrint("3. Celkový počet receptů v paměti: ${_recipes.length}");
              debugPrint("========================");

              setState(() => _selectedItem = item);
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