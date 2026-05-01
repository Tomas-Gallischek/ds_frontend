import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/game_menu.dart';
import '../widgets/ds_top_bar.dart';
import '../widgets/ds_equipment_slot.dart';
import '../widgets/ds_attribute_table.dart';
import '../services/api_service.dart';
import '../models/player_profile.dart'; 
import 'inventory_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PlayerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile(); 
  }

  // --- NAČTENÍ DAT Z BACKENDU ---
  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await ApiService().getPlayerProfile();
    
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  // --- POMOCNÁ FUNKCE: NAJDE NASAZENÝ PŘEDMĚT ---
  EqpItem? _getEquippedItem(String category) {
    if (_profile == null) return null;
    try {
      return _profile!.eqpItems.firstWhere(
        (item) => item.itemStatus == 'equipped' && item.category == category,
      );
    } catch (e) {
      return null;
    }
  }

  // --- POMOCNÁ FUNKCE: URČÍ SLOŽKU OBRÁZKU ---
  String? _getImgPath(EqpItem? item) {
    if (item == null) return null;
    String folder = 'accessories';
    if (item.category == 'weapon') {
      folder = 'weapons';
    }
    else if (item.category == 'armor') {
      folder = 'armor';
    }
    else if (item.category == 'helmet') {
      folder = 'helmet';
    }
    else if (item.category == 'boots') {
      folder = 'boots';
    }
    else if (item.category == 'amulet') {
      folder = 'amulet';
    }
    else if (item.category == 'ring') {
      folder = 'ring';
    }
    else if (item.category == 'talisman') {
      folder = 'talisman';
    }
    else if (item.category == 'pet') {
      folder = 'pet';
    }
    return 'assets/items/$folder/${item.itemImgOzn}.png';
  }

// --- FUNKCE PRO SUNDÁNÍ PŘEDMĚTU ---
    Future<void> _unequipItem(EqpItem item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sundávám: ${item.name}...'), duration: const Duration(seconds: 1)),
    );

    // OPRAVA 1: Přidán vykřičník u item.itemId!
    final success = await ApiService().toggleEquip(item.itemId!, item.name, 'inventory');
    
    // OPRAVA 2: Správný způsob ověření, zda je obrazovka stále aktivní (tzv. mounted)
    if (!mounted) return;
    
    Navigator.pop(context); // Zavře vyskakovací okno
    
    if (success) {
      _fetchProfile(); // Okamžitě načte nová data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba při sundávání! Zkus to znovu.'), backgroundColor: Colors.red),
      );
    }
  }

  // --- CHYTRÝ VYKRESLOVAČ SLOTŮ (S možností kliknutí) ---
// --- CHYTRÝ VYKRESLOVAČ SLOTŮ (S možností kliknutí a levelem) ---
  Widget _buildEquippedSlot(EqpItem? item, double size) {
    return GestureDetector(
      onTap: () {
        if (item != null) {
          _showItemDetails(context, item); // Pokud tu item je, otevřeme okno!
        }
      },
      child: Stack(
        children: [
          DsEquipmentSlot(
            itemImg: _getImgPath(item),
            rarity: item?.rarity ?? 'basic',
            size: size,
          ),
          // Pokud předmět existuje, vykreslíme jeho level do rohu
          if (item != null)
            Positioned(
              top: 12, 
              right: 20,
              child: Text(
                "+${item.itemLvl}", 
                style: TextStyle(
                  color: item.rarity == 'legendary' ? Colors.deepPurple : item.rarity == 'epic' ? Colors.redAccent : item.rarity == 'rare' ? Colors.orange : Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 20, 
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)]
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)),
      );
    }

    const double itemSize = 85.0; 

    // Načtení konkrétních slotů
    final helmet = _getEquippedItem('helmet');
    final armor = _getEquippedItem('armor');
    final boots = _getEquippedItem('boots');
    final amulet = _getEquippedItem('amulet');
    final ring = _getEquippedItem('ring');
    final pet = _getEquippedItem('pet');
    final weapon = _getEquippedItem('weapon');
    final talisman = _getEquippedItem('talisman');

    return Scaffold(
      appBar: DsTopBar(
        username: _profile!.username,
        level: _profile!.lvl,
        gold: _profile!.gold,
        dungeonTokens: _profile!.dungeonTokens,
        xpProgress: _profile!.xpProgress,
        avatarImg: 'assets/profile/${_profile!.avatar}.png',
      ),
      endDrawer: const GameMenu(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/bg/bg_dungeon_steps.png',
              fit: BoxFit.cover,
              color: Colors.black.withAlpha(153), 
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
                        
                        Text(
                          _profile!.username.toUpperCase(), 
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 18),
                            const SizedBox(width: 5),
                            Text("${_profile!.hpMax}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 25),
                            const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                            const SizedBox(width: 5),
                            Text("${_profile!.manaMax}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        
                        const SizedBox(height: 20),

                        // --- DYNAMICKÁ MŘÍŽKA VYBAVENÍ S KLIKÁNÍM ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: itemSize * 4, 
                              height: itemSize * 3, 
                              child: Stack(
                                children: [
                                  // LEVÁ STRANA
                                  Positioned(
                                    left: 0, top: 0,
                                    child: Column(
                                      children: [
                                        _buildEquippedSlot(helmet, itemSize),
                                        _buildEquippedSlot(armor, itemSize),
                                        _buildEquippedSlot(boots, itemSize),
                                      ],
                                    ),
                                  ),
                                  
                                  // PRAVÁ STRANA
                                  Positioned(
                                    right: 0, top: 0,
                                    child: Column(
                                      children: [
                                        _buildEquippedSlot(amulet, itemSize),
                                        _buildEquippedSlot(ring, itemSize),
                                        _buildEquippedSlot(pet, itemSize),
                                      ],
                                    ),
                                  ),

                                  // STŘED
                                  Positioned(
                                    left: itemSize, top: 0,
                                    child: SizedBox(
                                      width: itemSize * 2,
                                      height: itemSize * 3,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: itemSize * 2, height: itemSize * 2,
                                            decoration: BoxDecoration(
                                              color: AppTheme.panelDark,
                                              border: Border.all(color: AppTheme.panelWood, width: 3),
                                              image: DecorationImage(
                                                image: AssetImage('assets/profile/${_profile!.avatar}.png'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildEquippedSlot(weapon, itemSize),
                                              _buildEquippedSlot(talisman, itemSize),
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

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DsAttributeTable(profile: _profile!),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // SPODNÍ NAVIGACE
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(127),
                    border: const Border(top: BorderSide(color: AppTheme.panelWood, width: 2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInventoryBtn(context, Icons.shield, "Vybavení", 'equip'),
                      _buildInventoryBtn(context, Icons.auto_fix_high, "Materiály", 'material'),
                      _buildInventoryBtn(context, Icons.healing, "Spotřební", 'useable'),
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

  // --- OTEVŘENÍ INVENTÁŘE ---
  Widget _buildInventoryBtn(BuildContext context, IconData icon, String label, String filterType) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryScreen(
              title: label,
              filterCategory: filterType,
              allItems: _profile!.allItems,
            ),
          ),
        );
        if (result == true && context.mounted) {
          _fetchProfile();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // VYSKAKOVACÍ OKNO S DETAILEM PŘEDMĚTU
  // ==========================================
void _showItemDetails(BuildContext context, EqpItem item) {
  // Flag pro sledování, zda zrovna neprobíhá komunikace se serverem
  bool isProcessing = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.panelDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // StatefulBuilder umožňuje měnit stav (setState) pouze uvnitř tohoto BottomSheetu
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HLAVIČKA (Zůstává stejná)
                Row(
                  children: [
                    DsEquipmentSlot(
                      itemImg: _getImgPath(item),
                      rarity: item.rarity,
                      size: 70,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _getRarityColor(item.rarity))),
                          Text('${item.category.toUpperCase()} | Pož. Úroveň: ${item.lvlReq}', 
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          Text("+${item.itemLvl}", style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),

                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (item.description.isNotEmpty) ...[
                  Text(item.description, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 15),
                ],
                const Divider(color: AppTheme.panelWood, thickness: 2),

                // 2. STATY
                ..._buildItemStats(item),

                const SizedBox(height: 25),

                // 3. TLAČÍTKO SE ZÁMKEM (Pojistka proti double-clicku)
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton.icon(
                      // POKUD PROCES BĚŽÍ (isProcessing == true), onPressed VRÁTÍ NULL (Tlačítko zešedne a vypne se)
                      onPressed: isProcessing 
                        ? null 
                        : () async {
                            // Zamkneme tlačítko
                            setModalState(() => isProcessing = true);
                            
                            // Provedeme akci (volání API)
                            await _unequipItem(item);
                            
                            // Okno se zavírá v rámci _unequipItem, takže zde už setState nemusíme řešit
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isProcessing ? Colors.grey : Colors.redAccent.shade700,
                      ),
                      icon: isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.remove_circle_outline, color: Colors.white),
                      label: Text(
                        isProcessing ? "SUNDÁVÁM..." : "SUNDAT", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
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
  // POMOCNÉ FUNKCE PRO DETAIL PŘEDMĚTU
  // ==========================================
  List<Widget> _buildItemStats(EqpItem item) {
    List<Widget> rows = [];
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

    if (item.dmgMin > 0 || item.dmgMax > 0) addStat("Poškození", "${item.dmgMin} - ${item.dmgMax}", color: Colors.redAccent);
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

    return rows;
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.white;
    }
  }
}