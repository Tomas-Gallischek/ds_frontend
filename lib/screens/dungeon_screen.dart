import 'dart:async'; // Přidán import pro Timer
import 'package:flutter/material.dart';
import 'package:ds_frontend/services/api_service.dart';
import 'package:ds_frontend/screens/fight_screen.dart';

class DungeonScreen extends StatefulWidget {
  final int dungeonId;

  const DungeonScreen({super.key, required this.dungeonId});

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isStartingFight = false;
  
  Map<String, dynamic>? _dungeonData;
  Map<String, dynamic>? _profileData;

  // Nastavení posuvníku (slideru)
  double _selectedMinutes = 1.0; 
  final int _energyPerMinute = 1; // Cena energie za 1 minutu průzkumu

  // Proměnné pro systém "Zaneprázdněn do"
  DateTime? _busyUntil;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Důležité: Zrušení časovače při odchodu z obrazovky
    super.dispose();
  }

  // Načte data o dungeonu i o hráči (kvůli energy_points a busy_until)
  Future<void> _loadAllData() async {
    final dData = await _apiService.getDungeonDetails(widget.dungeonId);
    final pData = await _apiService.getProfile();
    
    if (!mounted) return;

    setState(() {
      _dungeonData = dData;
      _profileData = pData;
      
      // Vytáhnutí času busy_until, pokud existuje
      if (pData != null && pData['busy_until'] != null) {
        _busyUntil = DateTime.tryParse(pData['busy_until']);
        // Pokud je čas v budoucnosti, spustíme vizuální odpočet
        if (_busyUntil != null && _busyUntil!.isAfter(DateTime.now())) {
          _startCountdown();
        } else {
          _busyUntil = null; // Pokud čas už vypršel, smažeme ho
        }
      }
      
      _isLoading = false;
    });
  }

  // Funkce pro aktualizaci UI každou vteřinu, dokud čas nevyprší
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      if (_busyUntil != null && _busyUntil!.isAfter(DateTime.now())) {
        setState(() {}); // Překreslení UI každou vteřinu pro aktualizaci textu odpočtu
      } else {
        setState(() {
          _busyUntil = null; // Čas vypršel, hráč je volný
        });
        timer.cancel();
      }
    });
  }

  Future<void> _startFight() async {
    int? baseId = _dungeonData?['dungeon_base_id'];
    int currentEnergy = _profileData?['energy_points'] ?? 0;
    int requiredEnergy = _selectedMinutes.toInt() * _energyPerMinute;

    // 1) Kontrola, zda má hráč dostatek energie
    if (currentEnergy < requiredEnergy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máš málo energie na tak dlouhý průzkum!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (baseId == null) return;

    setState(() => _isStartingFight = true);

    // 2) Odeslání API s navolenou hodnotou jako 3. argumentem
    final turnLogs = await _apiService.initFight(baseId, "dungeon", _selectedMinutes.toInt());

    if (!mounted) return;
    setState(() => _isStartingFight = false);

    if (turnLogs != null && turnLogs.isNotEmpty) {
      // SOUBOJ ÚSPĚŠNÝ, MÁME DATA - JEDEME ANIMOVAT!
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FightScreen(turnLogs: turnLogs)),
      ).then((_) {
        // Po návratu z FightScreen (např. když souboj skončí), znovu načteme profil
        // Hráč by měl mít nastavený nový "busy_until" z backendu
        setState(() => _isLoading = true);
        _loadAllData();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba při zahájení souboje.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    // Výpočty pro UI ohledně energie
    int currentEnergy = _profileData?['energy_points'] ?? 0;
    int requiredEnergy = _selectedMinutes.toInt() * _energyPerMinute;
    bool hasEnoughEnergy = currentEnergy >= requiredEnergy;

    // --- LOGIKA PRO ZANEPRÁZDNĚNÍ ---
    bool isPlayerBusy = _busyUntil != null && _busyUntil!.isAfter(DateTime.now());
    String remainingTimeStr = "";
    
    if (isPlayerBusy) {
      Duration diff = _busyUntil!.difference(DateTime.now());
      String minutes = diff.inMinutes.toString().padLeft(2, '0');
      String seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      remainingTimeStr = "$minutes:$seconds";
    }

    // Tlačítko může být aktivní, jen když není zaneprázdněn, má energii a zrovna nenačítá
    bool canStartButton = hasEnoughEnergy && !isPlayerBusy && !_isStartingFight;

    String bgImageName = _dungeonData!['background_img'] ?? 'bg_default_dungeon';
    String dungeonName = _dungeonData!['name'] ?? 'Neznámý dungeon';
    String description = _dungeonData!['description'] ?? 'Temnota pohlcuje všechno světlo...';

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pozadí
          Image.asset(
            'assets/bg/dungeons/$bgImageName.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
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
                  
                  const Spacer(),

                  // --- CHYTRÝ POSUVNÍK (SLIDER) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: hasEnoughEnergy ? Colors.white24 : Colors.redAccent),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Musíš počkat ještě: ${_selectedMinutes.toInt()} min',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // Pokud je hráč na výpravě, slider zakážeme
                        Slider(
                          value: _selectedMinutes,
                          min: 1.0,
                          max: 20.0,
                          divisions: 19,
                          label: '${_selectedMinutes.toInt()} min',
                          activeColor: hasEnoughEnergy ? Colors.redAccent : Colors.red,
                          inactiveColor: Colors.white24,
                          onChanged: isPlayerBusy ? null : (value) {
                            setState(() {
                              _selectedMinutes = value;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Energie: $currentEnergy / 200',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Cena: $requiredEnergy Energie',
                              style: TextStyle(
                                color: hasEnoughEnergy ? Colors.amber : Colors.redAccent,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Tlačítko startu
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: canStartButton ? _startFight : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlayerBusy 
                          ? Colors.grey.shade700 
                          : (hasEnoughEnergy ? Colors.red.shade900 : Colors.grey.shade800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isStartingFight 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isPlayerBusy 
                                ? 'NA VÝPRAVĚ ($remainingTimeStr)' 
                                : (hasEnoughEnergy ? 'VSTOUPIT DO DUNGEONU' : 'NEDOSTATEK ENERGIE'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                          ),
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