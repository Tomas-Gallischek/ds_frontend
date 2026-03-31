import 'package:flutter/material.dart';
import 'package:ds_frontend/services/api_service.dart';

class DungeonScreen extends StatefulWidget {
  final int dungeonId; // Tento parametr přijmeme z mapy

  const DungeonScreen({super.key, required this.dungeonId});

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isStartingFight = false;
  Map<String, dynamic>? _dungeonData;

  @override
  void initState() {
    super.initState();
    _loadDungeonData();
  }

  Future<void> _loadDungeonData() async {
    // Voláme naši novou API metodu s IDčkem, které nám přišlo z mapy
    final data = await _apiService.getDungeonDetails(widget.dungeonId);
    
    if (!mounted) return;

    setState(() {
      _dungeonData = data;
      _isLoading = false;
    });
  }

  Future<void> _startFight() async {
    // Bezpečnostní kontrola, jestli máme data a v nich hledané ID
    int? baseId = _dungeonData?['dungeon_base_id'];
    if (baseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba: Data dungeonu neobsahují base_id!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Zamkneme tlačítko
    setState(() => _isStartingFight = true);

    // Zavoláme backend
    final success = await _apiService.initFight(baseId, "dungeon", 2); // POSLEDNÍ ARGUMENT SI PAK BUDE VYBÍRAT HRÁČ, JE TO ČAS SOUBOJE V MINUTÁCH

    // Nyní je 'mounted' kontrola naprosto bezpečná
    if (!mounted) return;

    // Odemkneme tlačítko
    setState(() => _isStartingFight = false);

    // Vyhodnocení výsledku
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Souboj úspěšně inicializován na serveru!'), backgroundColor: Colors.green),
      );
      // ZDE POZDĚJI PŘIDÁME NAVIGACI NA SOUBOJOVOU OBRAZOVKU
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodařilo se zahájit souboj. Zkontroluj připojení nebo staminu.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black, // Temné pozadí pro načítání dungeonu
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    if (_dungeonData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chyba')),
        body: const Center(child: Text('Dungeon se nepodařilo načíst.')),
      );
    }

    // Očekáváme, že z backendu přijde např. 'bg_dark_cave' (bez .png)
    String bgImageName = _dungeonData!['background_img'] ?? 'bg_default_dungeon';
    String dungeonName = _dungeonData!['name'] ?? 'Neznámý dungeon';
    String description = _dungeonData!['description'] ?? 'Temnota pohlcuje všechno světlo...';

    return Scaffold(
      // AppBar s průhledným pozadím, aby vynikl obrázek dungeonu
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 141, 123, 123),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Bílá šipka zpět
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. VRSTVA: Dynamický obrázek pozadí z backendu
          Image.asset(
            'assets/$bgImageName.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900),
          ),
          
          // Ztmavení obrázku, aby byl čitelný text
          Container(color: Colors.black.withValues(alpha: 0.6)),

          // 2. VRSTVA: Informace o dungeonu a tlačítka
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    dungeonName.toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Minimální úroveň: ${_dungeonData!['min_level'] ?? 'Neznámá'}',
                    style: const TextStyle(fontSize: 14, color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(), // Odsune tlačítka úplně dolů
                  
                  // Tlačítko pro inicializaci souboje
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // Zde už v pořádku odkazujeme na naši přesunutou metodu
                      onPressed: _isStartingFight ? null : _startFight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        disabledBackgroundColor: Colors.grey.shade800, // Barva zamknutého tlačítka
                        foregroundColor: Colors.white,
                      ),
                      // Zobrazíme buď text, nebo kolečko načítání
                      child: _isStartingFight 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text('VSTOUPIT DO TEMNOTY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}