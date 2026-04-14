class PlayerProfile {
  final String username;
  final int lvl;
  final int xp;
  final int xpNextLvl;
  final int gold;
  final int dungeonTokens;
  final int hpActual;
  final int hpMax;
  final int mana;
  final int manaMax;
  final int strength;
  final int dexterity;
  final int intelligence;
  final int vitality;
  final int luck;
  final int precision;
  final int dmgMin;
  final int dmgMax;
  final int armor;
  final double critChance;
  final String avatar;
  final int energyPoints; // PŘIDÁNO
  final DateTime? busyUntil; // PŘIDÁNO

  PlayerProfile({
    required this.username,
    required this.lvl,
    required this.xp,
    required this.xpNextLvl,
    required this.gold,
    required this.dungeonTokens,
    required this.hpActual,
    required this.hpMax,
    required this.mana,
    required this.manaMax,
    required this.strength,
    required this.dexterity,
    required this.intelligence,
    required this.vitality,
    required this.luck,
    required this.precision,
    required this.dmgMin,
    required this.dmgMax,
    required this.armor,
    required this.critChance,
    required this.avatar,
    required this.energyPoints,
    this.busyUntil,
  });

  // Metoda, která přechroustá JSON z Djanga na tento objekt
  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      username: json['username'] ?? 'Hrdina',
      lvl: json['lvl'] ?? 1,
      xp: json['xp'] ?? 0,
      xpNextLvl: json['xp_next_lvl'] ?? 100,
      gold: json['gold'] ?? 0,
      dungeonTokens: json['dungeon_tokens'] ?? 0,
      hpActual: json['hp_actual'] ?? 10,
      hpMax: json['hp_max'] ?? 10,
      // Předpokládáme manu a preciznost dle tvého zadání
      mana: json['mana'] ?? 50,
      manaMax: json['mana_max'] ?? 50,
      strength: json['str'] ?? 0,
      dexterity: json['dex'] ?? 0,
      intelligence: json['int'] ?? 0,
      vitality: json['vit'] ?? 0,
      luck: json['luck'] ?? 0,
      precision: json['precision'] ?? 0,
      dmgMin: json['dmg_min'] ?? 0,
      dmgMax: json['dmg_max'] ?? 0,
      armor: json['armor'] ?? 0,
      critChance: (json['crit_chance'] ?? 0).toDouble(),
      avatar: json['avatar'] ?? 'avatar_default',
      energyPoints: json['energy_points'] ?? 0,
      busyUntil: json['busy_until'] != null ? DateTime.parse(json['busy_until']) : null,
    );
  }

  // Pomocná funkce pro XP bar (0.0 až 1.0)
  double get xpProgress => (xp / xpNextLvl).clamp(0.0, 1.0);
}