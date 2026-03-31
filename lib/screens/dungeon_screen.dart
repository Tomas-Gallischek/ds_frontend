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

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Načte data o dungeonu i o hráči (kvůli energy_points)
  Future<void> _loadAllData() async {
    final dData = await _apiService.getDungeonDetails(widget.dungeonId);
    final pData = await _apiService.getProfile();
    
    if (!mounted) return;

    setState(() {
      _dungeonData = dData;
      _profileData = pData;
      _isLoading = false;
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
    // Předpokládám, že tvůj ApiService už tuto změnu v podpisu funkce přijal
// V dungeon_screen.dart:
    final turnLogs = await _apiService.initFight(baseId, "dungeon", _selectedMinutes.toInt());

    if (!mounted) return;
    setState(() => _isStartingFight = false);

    if (turnLogs != null && turnLogs.isNotEmpty) {
      // SOUBOJ ÚSPĚŠNÝ, MÁME DATA - JEDEME ANIMOVAT!
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FightScreen(turnLogs: turnLogs)),
      );
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

    // Výpočty pro UI
    int currentEnergy = _profileData?['energy_points'] ?? 0;
    int requiredEnergy = _selectedMinutes.toInt() * _energyPerMinute;
    bool hasEnoughEnergy = currentEnergy >= requiredEnergy;

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
            'assets/$bgImageName.png',
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
                          'Doba průzkumu: ${_selectedMinutes.toInt()} min',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: _selectedMinutes,
                          min: 1.0,
                          max: 20.0,
                          divisions: 19,
                          label: '${_selectedMinutes.toInt()} min',
                          activeColor: hasEnoughEnergy ? Colors.redAccent : Colors.red,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
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
                      onPressed: (_isStartingFight || !hasEnoughEnergy) ? null : _startFight,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasEnoughEnergy ? Colors.red.shade900 : Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isStartingFight 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            hasEnoughEnergy ? 'VSTOUPIT DO DUNGEONU' : 'NEDOSTATEK ENERGIE',
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