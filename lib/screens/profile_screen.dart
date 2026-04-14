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

  // Načtení skutečných dat z tvého Djanga
  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final data = await ApiService().getPlayerProfile();
    if (mounted) {
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Referenční velikost pro FittedBox (ten se postará o zbytek)
    const double itemSize = 85.0;

    if (_isLoading || _profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)),
      );
    }

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
          // 1. Pozadí
          Positioned.fill(
            child: Image.asset(
              'assets/bg/bg_dungeon_steps.png',
              fit: BoxFit.cover,
              color: Colors.black.withAlpha(160),
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

                        // --- ŠKÁLOVATELNÝ INVENTÁŘ (Mřížka 4x4 logika) ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: itemSize * 4,
                              child: Column(
                                children: [
                                  // Řada 1: Helma | Jméno (přes 2 sloty) | Amulet
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const DsEquipmentSlot(rarity: 'basic', size: itemSize),
                                      SizedBox(
                                        width: itemSize * 2,
                                        child: Column(
                                          children: [
                                            Text(
                                              _profile!.username.toUpperCase(),
                                              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                                              textAlign: TextAlign.center,
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.favorite, color: Colors.red, size: 14),
                                                const SizedBox(width: 4),
                                                Text("${_profile!.hpActual}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                const SizedBox(width: 12),
                                                const Icon(Icons.auto_awesome, color: Colors.blue, size: 14),
                                                const SizedBox(width: 4),
                                                Text("${_profile!.mana}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 5),
                                          ],
                                        ),
                                      ),
                                      const DsEquipmentSlot(rarity: 'epic', size: itemSize),
                                    ],
                                  ),

                                  // Střední část: Brnění | Profilovka (2x2) | Prsten
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          const DsEquipmentSlot(itemImg: 'assets/items/armor/kosile.png', rarity: 'basic', size: itemSize),
                                          const DsEquipmentSlot(rarity: 'basic', size: itemSize), // Boty (levý bok)
                                        ],
                                      ),
                                      // Centrální 2x2 Profilovka
                                      Container(
                                        width: itemSize * 2,
                                        height: itemSize * 2,
                                        decoration: BoxDecoration(
                                          color: AppTheme.panelDark,
                                          border: Border.all(color: AppTheme.panelWood, width: 3),
                                          image: DecorationImage(
                                            image: AssetImage('assets/profile/${_profile!.avatar}.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          const DsEquipmentSlot(rarity: 'legendary', size: itemSize),
                                          const DsEquipmentSlot(rarity: 'rare', size: itemSize), // Pet (pravý bok)
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Spodní řada (Uzavření "Účka"): Boty | Zbraň | Talisman | Pet
                                  // Pozn: Pro absolutní symetrii dáváme Boty a Peta do spodní řady
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const DsEquipmentSlot(rarity: 'basic', size: itemSize), // Spodní roh L
                                      DsEquipmentSlot(itemImg: 'assets/items/weapons/rezavy_nuz.png', rarity: 'rare', size: itemSize),
                                      const DsEquipmentSlot(rarity: 'basic', size: itemSize),
                                      const DsEquipmentSlot(rarity: 'rare', size: itemSize), // Spodní roh R
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- TABULKA ATRIBUTŮ (Reálná data) ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DsAttributeTable(profile: _profile!),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // SPODNÍ NAVIGACE INVENTÁŘE
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
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

  Widget _buildInventoryBtn(BuildContext context, IconData icon, String label, String type) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryScreen(
              title: label,
              filterCategory: type,
              allItems: [], // Zde později napojíme seznam itemů z _profile
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 28),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}