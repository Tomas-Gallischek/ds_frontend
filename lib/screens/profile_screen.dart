import 'package:flutter/material.dart';
import 'package:ds_frontend/services/api_service.dart';
import 'dart:async';
import 'package:ds_frontend/widgets/game_menu.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  
  // Proměnná, do které si uložíme celý ten JSON z backendu
  Map<String, dynamic>? _profileData; 
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData(); // Hned při zapnutí obrazovky jdeme stahovat data
  }
  @override
  void dispose() {
    _atrUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final data = await _apiService.getProfile();
    
    // Zabezpečení BuildContextu (už známe z minula)
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = 'Chyba při načítání profilu ze serveru.';
        _isLoading = false;
      });
    }
  }

// 1. a 2. krok: Lokální kontrola a Optimistický update
  void _handleAddAtr(String atr) {
    if (_profileData == null) return;
    
    int currentPoints = _profileData!['atr_points'] ?? 0;

    if (currentPoints <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nemáš dostatek bodů!'), duration: Duration(milliseconds: 500)),
      );
      return;
    }

    setState(() {
      // Snížení volných bodů a přidání do čekací listiny
      _profileData!['atr_points'] = currentPoints - 1;
      _pendingAtrUpdates[atr] = (_pendingAtrUpdates[atr] ?? 0) + 1;

      // Okamžité zvýšení konkrétní staty
      String maxKey = '${atr}_max';
      _profileData![maxKey] = (_profileData![maxKey] ?? 0) + 1;

      // Speciální výpočet HP při kliknutí na Vitalitu (podle tvé Kivy rovnice)
      if (atr == 'vit') {
        int vitMax = _profileData!['vit_max'] ?? 0;
        int hpVitKoef = _profileData!['hp_vit_koef'] ?? 0;
        int hpLvl = _profileData!['hp_lvl'] ?? 0;
        int hpBase = _profileData!['hp_base'] ?? 0;
        
        _profileData!['hp_max'] = (vitMax * hpVitKoef) + hpLvl + hpBase;
      }
    });

    // 3. krok: Časovač pro odeslání (Resetujeme ho, pokud hráč klikne rychle znovu)
    if (_atrUpdateTimer != null && _atrUpdateTimer!.isActive) {
      _atrUpdateTimer!.cancel();
    }

    // Odpočet 0.8s
    _atrUpdateTimer = Timer(const Duration(milliseconds: 800), _triggerSendAtrUpdates);
  }

  // Odpověď na vypršení časovače - Odeslání dat na backend
  Future<void> _triggerSendAtrUpdates() async {
    // Vytáhneme jen ty, co se reálně zvedly
    Map<String, int> updatesToSend = {};
    _pendingAtrUpdates.forEach((key, value) {
      if (value > 0) updatesToSend[key] = value;
    });

    // Vynulování lokální mapy
    _pendingAtrUpdates.updateAll((key, value) => 0);

    if (updatesToSend.isNotEmpty) {
      final success = await _apiService.addAtr(updatesToSend);
      if (!mounted) return;

      if (!success) {
        debugPrint("Chyba při odesílání na server. Obnovuji data z databáze.");
        // Pokud nastala chyba na síti nebo data nesedí, natáhneme jistotu z DB (Rollback)
        await _loadData(); 
      } else {
        debugPrint("Backend úspěšně zpracoval dávku: $updatesToSend");
      }
    }
  }


  // Proměnné pro dávkování atributů (Debouncing)
  Timer? _atrUpdateTimer;
    final Map<String, int> _pendingAtrUpdates = {
      'str': 0, 'dex': 0, 'int': 0, 'vit': 0, 'luck': 0
  };



  // Funkce, která řeší kliknutí na předmět v seznamu
  Future<void> _handleEquipToggle(int itemId, String itemName, String currentStatus) async {
    // Pokud je předmět v batohu, chceme ho nasadit (equipped). Pokud ho máme na sobě, chceme ho sundat (inventory).
    final newStatus = currentStatus == 'equipped' ? 'inventory' : 'equipped';
    
    // Zobrazíme hráči rychlou hlášku, že se něco děje
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manipuluji s předmětem: $itemName...'), duration: const Duration(seconds: 1)),
    );

    // Zavoláme naši novou službu
    final success = await _apiService.toggleEquip(itemId, itemName, newStatus);
    
    // Ochrana kontextu před pádem
    if (!mounted) return;

    if (success) {
      // Pokud backend potvrdil změnu, ZNOVU STÁHNEME PROFIL. 
      // Tím se automaticky aktualizují obě tabulky (Na sobě / Batoh) a přepočítají se staty!
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodařilo se manipulovat s předmětem. Zkus to znovu.')),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Hrdiny'),
        centerTitle: true,
        // Nastavení vlastních prvků napravo v liště
        actions: [
          // Používáme Builder, abychom získali správný "kontext" pro otevření menu.
          // Bez Builderu by aplikace nevěděla, který Scaffold má otevřít.
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.black, // Uprav na barvu, která sedí tvému tématu
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                  ),
                ),
              );
            }
          ),
        ],
      ),
      // Tímto napojíme náš vytvořený widget jako menu, které vyjíždí zprava
      endDrawer: const GameMenu(), 
      body: _buildBody(),
    );
  }

  // Rozdělení UI do samostatné metody pro lepší čitelnost
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    if (_profileData == null) {
      return const Center(child: Text('Žádná data k zobrazení.'));
    }

    // Nyní máme jistotu, že data jsou stažená. Můžeme je vykreslit.
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Hlavní karta se jménem, levelem a penězi
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- NOVÝ PROFILOVÝ OBRÁZEK ---
                CircleAvatar(
                  radius: 50, // Nastavuje velikost kruhu (poloměr)
                  backgroundColor: Colors.grey.shade300, // Barva pozadí, kdyby se obrázek nenačetl
                  // Dynamicky načteme obrázek podle stringu z backendu.
                  backgroundImage: AssetImage('assets/profile/${_profileData!['avatar_img_ozn']}.png'),
                ),
                const SizedBox(height: 16), // Mezera mezi obrázkem a jménem
                
                // --- PŮVODNÍ JMÉNO A STATISTIKY ---
                Text(
                  _profileData!['username'],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Úroveň: ${_profileData!['lvl']} | Zlato: ${_profileData!['gold']}',
                  style: const TextStyle(fontSize: 18, color: Colors.amber),
                ),
                const SizedBox(height: 8),
                Text(
                  'XP: ${_profileData!['xp']}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${_profileData!['role']}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Karta s atributy a HP
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistiky:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                Text('Životy (HP): ${_profileData!['hp_max']}', style: const TextStyle(fontSize: 16, color: Colors.green)),
                const SizedBox(height: 8),
                
                // TADY JE ZMĚNA: Používáme náš nový widget místo obyčejného Text()
                _buildStatRow('Síla', 'str'),
                _buildStatRow('Obratnost', 'dex'),
                _buildStatRow('Inteligence', 'int'),
                _buildStatRow('Vitalita', 'vit'),
                _buildStatRow('Štěstí', 'luck'),
                
                const Divider(),
                Text('Volné atributové body: ${_profileData!['atr_points']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16), // Mezera pod statistikami

        // --- NOVÉ SEKCE PRO PŘEDMĚTY ---
        const Text('Na sobě (Vybaveno):', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildEquippedItems(),
        const Divider(height: 32),

        const Text('Inventář (Batoh):', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInventoryItems(),
        const Divider(height: 32),

        const Text('Materiály:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildMaterials(),
        const SizedBox(height: 32), // Mezera na úplném konci obrazovky

      ],
    );
  }


  // Pomocný widget pro vykreslení ikonky itemu
  Widget _buildItemIcon(String imgName) {
    return ClipOval(
      child: Image.asset(
        'assets/items/$imgName.png', // Ujisti se, že nemáš v databázi uloženo ".png" přímo v názvu, jinak umaž '.png' zde
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48, 
          height: 48, 
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }


// Vykreslení věcí, které má hráč na sobě
  Widget _buildEquippedItems() {
    final List allEqpAble = _profileData!['all_items_eqp_able'] ?? [];
    final equipped = allEqpAble.where((item) => item['item_status'] == 'equipped').toList();

    if (equipped.isEmpty) {
      return const Text('Nemáš na sobě žádné vybavení.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Column(
      children: equipped.map((item) {
        return Card(
          color: Colors.blueGrey.shade50,
          child: ListTile(
            onTap: () => _handleEquipToggle(item['item_id'], item['name'], 'equipped'),
            // TADY JE ZMĚNA: Používáme novou funkci na obrázky
            leading: _buildItemIcon(item['item_img_ozn'].toString()),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['category']} | DMG: ${item['dmg_avg']} | Armor: ${item['armor']}'),
            trailing: const Icon(Icons.shield, color: Colors.blue),
          ),
        );
      }).toList(),
    );
  }

  // Vykreslení věcí, které leží v batohu
  Widget _buildInventoryItems() {
    final List allEqpAble = _profileData!['all_items_eqp_able'] ?? [];
    final inventory = allEqpAble.where((item) => item['item_status'] == 'inventory').toList();

    if (inventory.isEmpty) {
      return const Text('Tvůj batoh je prázdný.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Column(
      children: inventory.map((item) {
        return Card(
          child: ListTile(
            onTap: () => _handleEquipToggle(item['item_id'], item['name'], 'inventory'),
            // TADY JE ZMĚNA: Používáme novou funkci na obrázky
            leading: _buildItemIcon(item['item_img_ozn'].toString()),
            title: Text(item['name']),
            subtitle: Text('Lvl req: ${item['lvl_req']} | Klikni pro nasazení'), 
            trailing: Text('${item['price_ks']}g', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  // Vykreslení materiálů
  Widget _buildMaterials() {
    final List materials = _profileData!['all_items_material'] ?? [];

    if (materials.isEmpty) {
      return const Text('Nemáš žádné materiály.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Column(
      children: materials.map((item) {
        return Card(
          child: ListTile(
            // TADY JE ZMĚNA: Používáme novou funkci na obrázky (místo původní ikony kladiva)
            leading: _buildItemIcon(item['item_img_ozn'].toString()),
            title: Text(item['name']),
            subtitle: Text('Kategorie: ${item['category']}'),
            trailing: Text('x${item['amount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

// Pomocný widget pro jeden řádek atributu i s tlačítkem
  Widget _buildStatRow(String label, String atrKey) {
    int value = _profileData!['${atrKey}_max'] ?? 0;
    bool canUpgrade = (_profileData!['atr_points'] ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label: $value', style: const TextStyle(fontSize: 16)),
          // Zobrazíme + tlačítko, jen když má hráč volné body
          if (canUpgrade) 
            IconButton(
              icon: const Icon(Icons.add_box, color: Colors.green),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // Zruší zbytečně velké okraje
              onPressed: () => _handleAddAtr(atrKey), // ZDE VOLÁME NAŠI FUNKCI
            ),
        ],
      ),
    );
  }


}

