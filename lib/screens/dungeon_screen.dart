import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/player_profile.dart';
// import 'package:ds_frontend/screens/fight_screen.dart'; // Odkomentuj, až budeš mít připraveno

class DungeonScreen extends StatefulWidget {
  final int dungeonId;
  const DungeonScreen({super.key, required this.dungeonId});

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends State<DungeonScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  bool _isStartingFight = false; // Již se používá na tlačítku
  
  PlayerProfile? _profile; 

  double _selectedMinutes = 1.0; // Již se používá v posuvníku
  final int _energyPerMinute = 1;
  DateTime? _busyUntil;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final profile = await _apiService.getPlayerProfile();

    if (mounted) {
      setState(() {
        _profile = profile;
        _busyUntil = _profile?.busyUntil;
        _isLoading = false;
      });
      if (_busyUntil != null) _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_busyUntil == null || DateTime.now().isAfter(_busyUntil!)) {
        timer.cancel();
        _loadAllData();
      } else {
        setState(() {}); // Vynutí překreslení zbývajícího času
      }
    });
  }

  // Cvičná funkce pro start výpravy
  Future<void> _startFight() async {
    setState(() => _isStartingFight = true);

    // Zde později napojíš API: await _apiService.initFight(...)
    await Future.delayed(const Duration(seconds: 1)); 

    if (mounted) {
      setState(() => _isStartingFight = false);
      // Přesměrování do souboje
      // Navigator.push(context, MaterialPageRoute(builder: (context) => FightScreen(...)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
    }

    final bool isPlayerBusy = _busyUntil != null && DateTime.now().isBefore(_busyUntil!);
    final int requiredEnergy = (_selectedMinutes * _energyPerMinute).toInt();
    final bool hasEnoughEnergy = _profile!.energyPoints >= requiredEnergy;
    
    // Zjistíme, jestli tlačítko může být aktivní
    final bool canStartButton = !isPlayerBusy && hasEnoughEnergy && !_isStartingFight;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dungeon #${widget.dungeonId}"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Ukazatel energie a goldů nahoře
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatInfo(Icons.bolt, "${_profile!.energyPoints}", Colors.yellow),
                _buildStatInfo(Icons.monetization_on, "${_profile!.gold}", Colors.amber),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Informace uprostřed
          Text(
            "Průzkum Dungeonu",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          
          // Posuvník času (Zabrání varování unused_field)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                Text("Délka výpravy: ${_selectedMinutes.toInt()} min"),
                Slider(
                  value: _selectedMinutes,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.red.shade800,
                  inactiveColor: Colors.grey.shade800,
                  onChanged: isPlayerBusy ? null : (val) {
                    setState(() {
                      _selectedMinutes = val;
                    });
                  },
                ),
                Text(
                  "Cena: $requiredEnergy Energie",
                  style: TextStyle(color: hasEnoughEnergy ? Colors.green : Colors.red),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Tlačítko pro vstup (Zabrání varování unused_field)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
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
                          ? "HRDINA JE NA VÝPRAVĚ" 
                          : (hasEnoughEnergy ? "VSTOUPIT" : "NEDOSTATEK ENERGIE"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}