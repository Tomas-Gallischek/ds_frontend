import 'dart:async';
import 'package:flutter/material.dart';

class FightScreen extends StatefulWidget {
  final List<dynamic> turnLogs;

  const FightScreen({super.key, required this.turnLogs});

  @override
  State<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends State<FightScreen> {
  // Časovač a Stopky pro plynulý běh "filmu"
  late Stopwatch _stopwatch;
  Timer? _ticker;
  int _currentIndex = 0;
  bool _isFinished = false;

  // Herní stav (načte se na začátku z 1. logu)
  int _wave = 1;
  String _playerName = "Hráč";
  String _playerImg = "avatar_default";
  double _playerHp = 1;
  double _playerMaxHp = 1;

  String _enemyName = "Nepřítel";
  String _enemyImg = "None";
  double _enemyHp = 1;
  double _enemyMaxHp = 1;

  // Proměnné pro animaci skoku (útoku)
  double _playerOffset = 0.0;
  double _enemyOffset = 0.0;

  // Seznam pro vyskakující poškození
  final List<FloatingText> _floatingTexts = [];
  
  // Chceš, aby souboj běžel rychleji než reálně? Dej např. 2.0 nebo 5.0
  final double _timeMultiplier = 1.0; 

// Zde se bude ukládat a sčítat kořist během přehrávání animace
  final Map<String, int> _accumulatedLoot = {};

  @override
  void initState() {
    super.initState();
    _initInitialState();
    _startFight();
  }

void _initInitialState() {
    if (widget.turnLogs.isEmpty) {
      _isFinished = true;
      return;
    }

    // --- OPRAVA 1: Převod relativního času na absolutní ---
    double timeAdder = 0.0;
    double lastOffset = 0.0;
    
    for (var log in widget.turnLogs) {
      double currentOffset = (log['time_offset'] as num).toDouble();
      
      // Pokud čas klesl (např. z 20.0 na 0.85), znamená to novou vlnu.
      // Přičteme k timeAdder hodnotu konce předchozí vlny.
      if (currentOffset < lastOffset) {
        timeAdder += lastOffset;
      }
      
      // Uložíme si novou absolutní hodnotu času přímo do logu
      log['absolute_time'] = currentOffset + timeAdder;
      lastOffset = currentOffset;
    }
    // --------------------------------------------------------

    // Připravíme scénu z prvního řádku scénáře
    final firstLog = widget.turnLogs.first;
    _wave = firstLog['wave'] ?? 1;

    bool pAttacking = firstLog['is_attacker_player'] == true;
    _playerName = pAttacking ? firstLog['attacker'] : firstLog['defender'];
    _enemyName = pAttacking ? firstLog['defender'] : firstLog['attacker'];

    _playerMaxHp = (pAttacking ? firstLog['attacker_max_hp'] : firstLog['defender_max_hp']).toDouble();
    _enemyMaxHp = (pAttacking ? firstLog['defender_max_hp'] : firstLog['attacker_max_hp']).toDouble();
    _playerHp = (pAttacking ? firstLog['attacker_hp'] : firstLog['defender_hp']).toDouble();
    _enemyHp = (pAttacking ? firstLog['defender_hp'] : firstLog['attacker_hp']).toDouble();

    _playerImg = firstLog['player_img'] ?? 'avatar_default';
    _enemyImg = firstLog['enemy_img'] ?? 'None';
  }

  void _startFight() {
    _stopwatch = Stopwatch()..start();
    // Ticker běží každých 30ms (cca 33 FPS) a hlídá čas pro další útok
    _ticker = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      _updateLogic();
    });
  }

void _updateLogic() {
    if (_isFinished) return;

    double elapsedSeconds = (_stopwatch.elapsedMilliseconds / 1000.0) * _timeMultiplier;
    bool stateChanged = false;

    // Spustíme všechny logy, jejichž čas už nastal!
    while (_currentIndex < widget.turnLogs.length) {
      final log = widget.turnLogs[_currentIndex];
      // OPRAVA: Tady čteme náš nový přepočítaný absolutní čas!
      double offset = (log['absolute_time'] as num).toDouble();

      if (elapsedSeconds >= offset) {
        _processLog(log);
        _currentIndex++;
        stateChanged = true;
      } else {
        break; // Další událost ještě nenastala
      }
    }

    if (_currentIndex >= widget.turnLogs.length) {
      _finishFight();
      stateChanged = true;
    }

    // Promazání starých vyskakujících textů po 800ms
    final now = DateTime.now();
    if (_floatingTexts.any((t) => now.difference(t.createdAt).inMilliseconds > 800)) {
      _floatingTexts.removeWhere((t) => now.difference(t.createdAt).inMilliseconds > 800);
      stateChanged = true;
    }

    if (stateChanged && mounted) {
      setState(() {});
    }
  }

void _processLog(Map<String, dynamic> log) {
    _wave = log['wave'] ?? _wave;
    bool pAttacking = log['is_attacker_player'] == true;
    String eventType = log['event_type'] ?? '';

    // OPRAVA 2: Aktualizace nejen HP, ale i MAX HP!
    if (pAttacking) {
      _playerHp = (log['attacker_hp'] as num).toDouble();
      _playerMaxHp = (log['attacker_max_hp'] as num).toDouble(); // Nové
      _enemyHp = (log['defender_hp'] as num).toDouble();
      _enemyMaxHp = (log['defender_max_hp'] as num).toDouble(); // Nové
      _enemyName = log['defender'];
    } else {
      _playerHp = (log['defender_hp'] as num).toDouble();
      _playerMaxHp = (log['defender_max_hp'] as num).toDouble(); // Nové
      _enemyHp = (log['attacker_hp'] as num).toDouble();
      _enemyMaxHp = (log['attacker_max_hp'] as num).toDouble(); // Nové
      _enemyName = log['attacker'];
    }
    
    // Nový obrázek nepřítele, pokud začala další vlna
    _playerImg = log['player_img'] ?? _playerImg;
    _enemyImg = log['enemy_img'] ?? _enemyImg;

    // Přehrání animací podle toho, co se stalo
    if (eventType == 'player_attack') {
      _animateAttack(isPlayer: true);
      _showDamage(log['damage'], log['damage_status'], isPlayerTarget: false);
    } else if (eventType == 'enemy_attack') {
      _animateAttack(isPlayer: false);
      _showDamage(log['damage'], log['damage_status'], isPlayerTarget: true);
    } else if (eventType == 'enemy_defeated') {
      _animateAttack(isPlayer: true);
      _showDamage(log['damage'], log['damage_status'], isPlayerTarget: false);
    }

// --- PŘIDÁNO: Zpracování kořisti ---
    if (log.containsKey('loot_dropped') && log['loot_dropped'] != null) {
      List<dynamic> droppedItems = log['loot_dropped'];
      for (var item in droppedItems) {
        String itemName = item['name'];
        int amount = item['amount'];
        
        // Pokud už item v Mapě je, přičte k němu amount. Pokud není, založí ho s hodnotou amount.
        _accumulatedLoot[itemName] = (_accumulatedLoot[itemName] ?? 0) + amount;
      }
    }


  }

void _animateAttack({required bool isPlayer}) {
    if (isPlayer) {
      _playerOffset = 50.0; // Skočí doprava
    } else {
      _enemyOffset = -50.0; // Skočí doleva
    }

    // Okamžitý návrat zpět na pozici po 150 milisekundách
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          // OPRAVENO: Přidány složené závorky, jak editor vyžaduje
          if (isPlayer) {
            _playerOffset = 0;
          } else {
            _enemyOffset = 0;
          }
        });
      }
    });
  }

  void _showDamage(dynamic damage, String status, {required bool isPlayerTarget}) {
    _floatingTexts.add(FloatingText(
      amount: damage.toString(),
      isCritical: status == 'critical',
      isPlayerTarget: isPlayerTarget,
      createdAt: DateTime.now(),
    ));
  }

  void _skipAnimation() {
    if (_isFinished) return;
    // Bleskově projedeme všechny zbývající logy bez zdržování
    while (_currentIndex < widget.turnLogs.length) {
      _processLog(widget.turnLogs[_currentIndex]);
      _currentIndex++;
    }
    _finishFight();
    setState(() {});
  }

  void _finishFight() {
    _isFinished = true;
    _ticker?.cancel();
    _stopwatch.stop();
  }

  String _formatTime() {
    if (_currentIndex == 0 && !_isFinished) return "00:00";
    
    double seconds = 0;
    if (_isFinished && widget.turnLogs.isNotEmpty) {
      seconds = (widget.turnLogs.last['time_offset'] as num).toDouble();
    } else {
      seconds = _stopwatch.elapsedMilliseconds / 1000.0 * _timeMultiplier;
    }

    int m = seconds ~/ 60;
    int s = (seconds % 60).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildHealthBar(double hp, double maxHp) {
    double percent = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0;
    // Barva plynule mění barvu podle toho, kolik má života
    Color barColor = percent > 0.5 ? Colors.green : (percent > 0.2 ? Colors.orange : Colors.red);

    return Column(
      children: [
        Text('${hp.toInt()} / ${maxHp.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: AnimatedContainer( // Plynulý úbytek HP díky AnimatedContaineru
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ],
    );
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Vlna $_wave', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer ve formátu 00:00
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _formatTime(),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
            ),
            
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- NOVÝ HLAVNÍ SLOUPEC ---
                  // Tento sloupec drží nahoře postavy a dole pod nimi kořist
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Postavy a Healthbary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // HRÁČ (LEVO)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_playerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                transform: Matrix4.translationValues(_playerOffset, 0, 0),
                                child: Image.asset(
                                  'assets/$_playerImg.png',
                                  width: 140,
                                  height: 140,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 140, color: Colors.blueAccent),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildHealthBar(_playerHp, _playerMaxHp),
                            ],
                          ),

                          const Text('VS', style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold)),

                          // NEPŘÍTEL (PRAVO)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_enemyName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                transform: Matrix4.translationValues(_enemyOffset, 0, 0),
                                child: Image.asset(
                                  'assets/$_enemyImg.png',
                                  width: 140,
                                  height: 140,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.pest_control, size: 140, color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Konec sloupce nepřítele hned za healthbarem!
                              _buildHealthBar(_enemyHp, _enemyMaxHp),
                            ],
                          ),
                        ],
                      ), // Konec Row (řádku) s postavami

                      // --- PŘESUNUTÝ BOX S KOŘISTÍ ---
                      // Nyní je správně pod řádkem s postavami
                      const SizedBox(height: 30), 
                      
                      if (_accumulatedLoot.isNotEmpty)
                        Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ZÍSKANÁ KOŘIST:',
                                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: _accumulatedLoot.entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${entry.key}  x${entry.value}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Plovoucí texty zranění (Damage Popups)
                  ..._floatingTexts.map((ft) {
                    int ageMs = DateTime.now().difference(ft.createdAt).inMilliseconds;
                    double moveY = -(ageMs / 800.0) * 80.0; 

                    return Positioned(
                      left: ft.isPlayerTarget ? MediaQuery.of(context).size.width * 0.20 : null,
                      right: ft.isPlayerTarget ? null : MediaQuery.of(context).size.width * 0.20,
                      top: MediaQuery.of(context).size.height * 0.25 + moveY,
                      child: Text(
                        ft.amount == '0' ? 'Miss' : '-${ft.amount}',
                        style: TextStyle(
                          color: ft.amount == '0' ? Colors.grey : (ft.isCritical ? Colors.yellowAccent : Colors.redAccent),
                          fontSize: ft.isCritical ? 42 : 28, 
                          fontWeight: FontWeight.bold,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 2))],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Tlačítko na přeskočení / zavření
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isFinished ? () => Navigator.pop(context) : _skipAnimation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFinished ? Colors.green.shade800 : Colors.red.shade900,
                  ),
                  child: Text(
                    _isFinished ? 'ZAVŘÍT A ZOBRAZIT ODMĚNY' : 'PŘESKOČIT ANIMACI',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class FloatingText {
  final String amount;
  final bool isCritical;
  final bool isPlayerTarget; // Říká, na koho ten text má vyskočit (doleva / doprava)
  final DateTime createdAt;

  FloatingText({required this.amount, required this.isCritical, required this.isPlayerTarget, required this.createdAt});
}