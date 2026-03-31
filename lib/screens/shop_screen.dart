import 'package:flutter/material.dart';
import 'package:ds_frontend/services/api_service.dart';
import 'package:ds_frontend/widgets/game_menu.dart';
import 'dart:async'; // Potřebujeme pro časovače


class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  // Přidáno 'with SingleTickerProviderStateMixin' pro správu TabControlleru
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  late TabController _tabController; // Náš nový správce záložek
  
  bool _isLoading = true;
  List<dynamic>? _shopItems;
  Map<String, dynamic>? _profileData;
  final Map<int, int> _pendingSales = {};
  final Map<int, Timer> _saleTimers = {};

  bool _isProcessingTransaction = false;

  @override
  void initState() {
    super.initState();
    // Inicializace TabControlleru se 2 záložkami
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData(tichyChod: false);
  }

@override
  void dispose() {
    _tabController.dispose();
    // Úklid všech aktivních časovačů
    for (var timer in _saleTimers.values) {
      timer.cancel();
    }
    _saleTimers.clear();
    super.dispose();
  }

  // Přidán parametr tichyChod. Pokud je true, neukazujeme točící se kolečko.
  Future<void> _loadAllData({bool tichyChod = true}) async {
    if (!tichyChod) {
      setState(() => _isLoading = true);
    }
    
    final shopData = await _apiService.getShopItems();
    final profileData = await _apiService.getProfile();



    if (!mounted) return;

    setState(() {
      _shopItems = shopData;
      _profileData = profileData;
      _isLoading = false;
    });


  }

  

// --- NÁKUP S POTVRZENÍM, ZÁMKEM A OKAMŽITÝM ZMIZENÍM ---
  Future<void> _handleBuy(dynamic item) async {
    // Pokud už nějaká transakce probíhá, ignorujeme další kliknutí
    if (_isProcessingTransaction) return;

    int price = (item['price_ks'] ?? 0).toInt();
    int myGold = (_profileData?['gold'] ?? 0).toInt();
    int itemId = item['item_id'];

    if (myGold < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nedostatek zlata!')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Potvrzení nákupu', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('Opravdu si přeješ koupit vybavení "${item['name']}" za ${price}g?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Zrušit', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100),
              child: const Text('Koupit', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    // --- ZAMKNUTÍ UI A OPTIMISTICKÝ UPDATE ---
    setState(() {
      _isProcessingTransaction = true; // Zamykáme všechna tlačítka
      _profileData!['gold'] = myGold - price; // Hned odečteme zlato
      _shopItems?.removeWhere((shopItem) => shopItem['item_id'] == itemId); // Hned necháme zmizet item
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kupuji: ${item['name']}...'), duration: const Duration(milliseconds: 1500)),
    );

    // Čekáme na server
    final success = await _apiService.buyItem(itemId, item['name'], price);
    
    if (!mounted) return;

    if (success) {
      await _loadAllData(tichyChod: true); 
      if (!mounted) return;
      
      setState(() {
        _isProcessingTransaction = false; // Odemkneme tlačítka
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Úspěšně zakoupeno: ${item['name']}!'), backgroundColor: Colors.green),
      );
    } else {
      // ROLLBACK: Pokud nákup selhal, stáhneme data znovu (item se vrátí do obchodu)
      await _loadAllData(tichyChod: true); 
      if (!mounted) return;
      
      setState(() {
        _isProcessingTransaction = false; // Odemkneme tlačítka
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nákup se nezdařil. Vracím zlato a položku.'), backgroundColor: Colors.red),
      );
    }
  }

// --- 1. KROK: KLIKNUTÍ NA PRODEJ (Optimistický UI a Debouncing) ---
  void _handleSellClick(dynamic item) {
    int itemId = item['item_id'];
    int currentAmount = item['amount'] ?? 0;

    // Lokální kontrola: Máme co prodávat?
    if (currentAmount <= 0) return;

    // --- OPTIMISTICKÝ UPDATE UI ---
    setState(() {
      // 1. Zvýšíme zlato
      int currentGold = (_profileData?['gold'] ?? 0).toInt();
      _profileData!['gold'] = currentGold + (item['price_ks'] ?? 0).toInt();
      
      // 2. Snížíme počet kusů v batohu
      item['amount'] = currentAmount - 1;
      
      // 3. Zaznamenáme si kliknutí do mapy k prodeji
      _pendingSales[itemId] = (_pendingSales[itemId] ?? 0) + 1;
    });

    // --- SPRÁVA ČASOVAČE (Debouncing) pro konkrétní ID ---
    // Pokud pro tento item už běží časovač, zrušíme ho (hráč kliknul znova moc rychle)
    if (_saleTimers.containsKey(itemId) && _saleTimers[itemId]!.isActive) {
      _saleTimers[itemId]!.cancel();
    }

    // Nastavíme nový odpočet 0.8s pro toto konkrétní ID
    _saleTimers[itemId] = Timer(const Duration(milliseconds: 800), () {
      _executeSaleBatch(item);
    });
  }

  // --- 2. KROK: ODESLÁNÍ DÁVKY PRODANÝCH KUSŮ NA BACKEND ---
  Future<void> _executeSaleBatch(dynamic item) async {
    int itemId = item['item_id'];
    int price = (item['price_ks'] ?? 0).toInt();
    
    // Vytáhneme z mapy, kolik kusů jsme celkem naklikali
    int amountToSell = _pendingSales[itemId] ?? 0;

    // Vyčistíme sledování pro toto ID, než začneme posílat data
    _pendingSales.remove(itemId);
    _saleTimers.remove(itemId);

    if (amountToSell <= 0) return; // Pojistka

    debugPrint('Odesílám prodej: ${item['name']} (ID: $itemId), množství: $amountToSell');

    // VOLÁNÍ NA BACKEND (Zde posíláme backendu nové množství - parametr 'amount')
    // POZOR: Musíš upravit API Service metodu sellItem, aby přijímala amount!
    final success = await _apiService.sellItem(itemId, item['name'], price, amountToSell);
    
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Prodáno: ${item['name']} ($amountToSell ks) za ${price * amountToSell}g'),
        duration: const Duration(seconds: 1),
      ));
      // Tiché dotažení dat (pro jistotu srovnáme stav s databází bez probliknutí)
      await _loadAllData(tichyChod: true);
    } else {
      // --- ROLLBACK V PŘÍPADĚ CHYBY SÍTĚ ---
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prodej se nezdařil. Synchronizuji data.')));
      // V případě chyby načteme čistá data ze serveru (vrátí nám itemy i zlato)
      await _loadAllData(tichyChod: true);
    }
  }

  // --- REFRESH ---
  Future<void> _handleRefresh() async {
    int myGold = (_profileData?['gold'] ?? 0).toInt();
    if (myGold < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Na refresh potřebuješ aspoň 100g!')));
      return;
    }

    // Optimisticky odečteme zlato
    setState(() {
      _profileData!['gold'] = myGold - 100;
    });

    final success = await _apiService.refreshShop();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obchod byl obnoven!')));
      await _loadAllData(tichyChod: false); // Tady chceme kolečko načítání, protože se mění celý obchod
    } else {
      setState(() => _profileData!['gold'] = myGold); // Rollback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refresh se nezdařil.')));
    }
  }

  Widget _buildItemIcon(String imgName) {
    return ClipOval(
      child: Image.asset(
        'assets/items/$imgName.png',
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 48, height: 48, color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int currentGold = (_profileData?['gold'] ?? 0).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Místní Kupec'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              child: const Text('MENU', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        // TabBar nyní používá náš explicitní controller
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'NABÍDKA (Nákup)'),
            Tab(text: 'TVŮJ BATOH (Prodej)'),
          ],
        ),
      ),
      endDrawer: const GameMenu(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.amber.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tvé zlato: $currentGold g', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh (-100g)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                )
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController, // Napojení na náš controller
              children: [
                _buildShopTab(),
                _buildInventoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTab() {
    if (_shopItems == null || _shopItems!.isEmpty) {
      return const Center(child: Text('Kupec nemá žádné zboží.'));
    }

    return ListView.builder(
      itemCount: _shopItems!.length,
      itemBuilder: (context, index) {
        final item = _shopItems![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _buildItemIcon(item['item_img_ozn'].toString()),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item['category']} | Lvl req: ${item['lvl_req']}'),
            trailing: ElevatedButton(
              // ZDE JE ZMĚNA: Pokud proces běží, onPressed je null (tlačítko se deaktivuje)
              onPressed: _isProcessingTransaction ? null : () => _handleBuy(item),
              
              // ZDE JE ZMĚNA: Deaktivované tlačítko bude šedé, aktivní zelené
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessingTransaction ? Colors.grey.shade300 : Colors.green.shade100,
                foregroundColor: _isProcessingTransaction ? Colors.grey.shade600 : Colors.green.shade900,
              ),
              child: Text('Koupit (${item['price_ks']}g)'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    final List eqpItems = _profileData?['all_items_eqp_able'] ?? [];
    final inventoryItems = eqpItems.where((i) => i['item_status'] == 'inventory').toList();
    final List materials = _profileData?['all_items_material'] ?? [];
    
    // Vyfiltrujeme věci, u kterých jsme "optimisticky" snížili počet na 0 a méně
    final List allSellable = [...inventoryItems, ...materials].where((item) => (item['amount'] ?? 1) > 0).toList();

    if (allSellable.isEmpty) {
      return const Center(child: Text('Nemáš nic k prodeji.'));
    }

    return ListView.builder(
      itemCount: allSellable.length,
      itemBuilder: (context, index) {
        final item = allSellable[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _buildItemIcon(item['item_img_ozn'].toString()),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Množství: ${item['amount']}x'),
            trailing: ElevatedButton(
              onPressed: () => _handleSellClick(item), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              child: Text('Prodat (+${item['price_ks']}g)'),
            ),
          ),
        );
      },
    );
  }
}