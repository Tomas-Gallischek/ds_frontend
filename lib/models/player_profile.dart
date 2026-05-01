// ---------------------------------------------------------
// ZÁKLADNÍ TŘÍDY PRO ITEMY (Díky tomuto můžeme míchat vybavení a materiály)
// ---------------------------------------------------------
abstract class BaseItem {
  final int? itemId; // NOVÉ: ID konkrétní položky v inventáři hráče (nejen základní ID)
  final int? itemBaseId;
  final String name;
  final String description;
  final String itemImgOzn;
  final String itemStatus;
  final int amount;
  final String category;
  final int lvlReq;
  final String rarity;
  final int priceKs;
  final int priceAll;
  final int itemLvl;
  final double weaponDmgUpKoef;
  final double armorArmorUpKoef;
  final double armorHpUpKoef;
  final double helmetArmorUpKoef;
  final double bootsArmorUpKoef;
  final double bootsAttackSpeedUpKoef;
  final double amuletAtrUpKoef;
  final double ringAtrUpKoef;

  BaseItem({
    required this.itemId,
    this.itemBaseId,
    required this.name,
    required this.description,
    required this.itemImgOzn,
    required this.itemStatus,
    required this.amount,
    required this.category,
    required this.lvlReq,
    required this.rarity,
    required this.priceKs,
    required this.priceAll,
    required this.itemLvl,
    required this.weaponDmgUpKoef,
    required this.armorArmorUpKoef,
    required this.armorHpUpKoef,
    required this.helmetArmorUpKoef,
    required this.bootsArmorUpKoef,
    required this.bootsAttackSpeedUpKoef,
    required this.amuletAtrUpKoef,
    required this.ringAtrUpKoef,
  });
}

// TŘÍDA PRO VYBAVENÍ
class EqpItem extends BaseItem {
  final dynamic itemBonusy;
  final int armor;
  final String? dmgType;
  final int dmgMin;
  final int dmgMax;
  final int dmgAvg;
  final double attackSpeedWeapon;
  final double attackSpeedArmor;
  final double attackSpeedHelmet;
  final double attackSpeedBoots;
  final int plusHp;
  final int? allAtrBonusAmulet;
  final int? allAtrBonusRing;
  final String? talismanBonusName;
  final String? talismanBonusType;
  final int? talismanBonusValue;
  final int? petLvl;
  final int? petArmorBonus;
  final int? petDmgBonus;
  final int? petHpBonus;
  final int? petPrumSkodaBonus;

  EqpItem({
    super.itemId,
    super.itemBaseId,
    required super.name,
    required super.description,
    required super.itemImgOzn,
    required super.itemStatus,
    required super.amount,
    required super.category,
    required super.lvlReq,
    required super.rarity,
    required super.priceKs,
    required super.priceAll,
    required super.itemLvl,
    required super.weaponDmgUpKoef,
    required super.armorArmorUpKoef,
    required super.armorHpUpKoef,
    required super.helmetArmorUpKoef,
    required super.bootsArmorUpKoef,
    required super.bootsAttackSpeedUpKoef,
    required super.amuletAtrUpKoef,
    required super.ringAtrUpKoef,
    this.itemBonusy,
    required this.armor,
    this.dmgType,
    required this.dmgMin,
    required this.dmgMax,
    required this.dmgAvg,
    required this.attackSpeedWeapon,
    required this.attackSpeedArmor,
    required this.attackSpeedHelmet,
    required this.attackSpeedBoots,
    required this.plusHp,
    this.allAtrBonusAmulet,
    this.allAtrBonusRing,
    this.talismanBonusName,
    this.talismanBonusType,
    this.talismanBonusValue,
    this.petLvl,
    this.petArmorBonus,
    this.petDmgBonus,
    this.petHpBonus,
    this.petPrumSkodaBonus,
  });

  factory EqpItem.fromJson(Map<String, dynamic> json) {
    return EqpItem(
      itemId: json['item_id'] ?? 0, // <--- NOVÉ
      itemBaseId: json['item_base_id'],
      name: json['name'] ?? 'Neznámý předmět',
      description: json['description'] ?? '',
      itemImgOzn: json['item_img_ozn'] ?? 'item_default',
      itemStatus: json['item_status'] ?? 'inventory',
      amount: (json['amount'] as num?)?.toInt() ?? 1, // BEZPEČNÁ KONVERZE
      category: json['category'] ?? 'unknown',
      lvlReq: (json['lvl_req'] as num?)?.toInt() ?? 1,
      rarity: json['rarity'] ?? 'basic',
      priceKs: (json['price_ks'] as num?)?.toInt() ?? 0,
      priceAll: (json['price_all'] as num?)?.toInt() ?? 0,
      itemBonusy: json['item_bonusy'],
      armor: (json['armor'] as num?)?.toInt() ?? 0,
      dmgType: json['dmg_type'],
      dmgMin: (json['dmg_min'] as num?)?.toInt() ?? 0,
      dmgMax: (json['dmg_max'] as num?)?.toInt() ?? 0,
      dmgAvg: (json['dmg_avg'] as num?)?.toInt() ?? 0,
      attackSpeedWeapon: (json['attack_speed_weapon'] as num?)?.toDouble() ?? 0.0,
      attackSpeedArmor: (json['attack_speed_armor'] as num?)?.toDouble() ?? 0.0,
      attackSpeedHelmet: (json['attack_speed_helmet'] as num?)?.toDouble() ?? 0.0,
      attackSpeedBoots: (json['attack_speed_boots'] as num?)?.toDouble() ?? 0.0,
      plusHp: (json['plus_hp'] as num?)?.toInt() ?? 0,
      allAtrBonusAmulet: (json['all_atr_bonus_amulet'] as num?)?.toInt(),
      allAtrBonusRing: (json['all_atr_bonus_ring'] as num?)?.toInt(),
      talismanBonusName: json['talisman_bonus_name'],
      talismanBonusType: json['talisman_bonus_type'],
      talismanBonusValue: (json['talisman_bonus_value'] as num?)?.toInt(),
      petLvl: (json['pet_lvl'] as num?)?.toInt(),
      petArmorBonus: (json['pet_armor_bonus'] as num?)?.toInt(),
      petDmgBonus: (json['pet_dmg_bonus'] as num?)?.toInt(),
      petHpBonus: (json['pet_hp_bonus'] as num?)?.toInt(),
      petPrumSkodaBonus: (json['pet_prum_skoda_bonus'] as num?)?.toInt(),
      itemLvl: (json['item_lvl'] as num?)?.toInt() ?? 0,
      weaponDmgUpKoef: double.tryParse(json['weapon_dmg_up_koef']?.toString() ?? '') ?? 0.0,
      armorArmorUpKoef: double.tryParse(json['armor_up_koef_ARMOR']?.toString() ?? '') ?? 0.0,
      armorHpUpKoef: double.tryParse(json['armor_up_koef_HP']?.toString() ?? '') ?? 0.0,
      helmetArmorUpKoef: double.tryParse(json['helmet_armor_up_koef']?.toString() ?? '') ?? 0.0,
      bootsArmorUpKoef: double.tryParse(json['boots_armor_up_koef']?.toString() ?? '') ?? 0.0,
      bootsAttackSpeedUpKoef: double.tryParse(json['boots_attack_speed_up_koef']?.toString() ?? '') ?? 0.0,
      amuletAtrUpKoef: double.tryParse(json['amulet_atr_up_koef']?.toString() ?? '') ?? 0.0,
      ringAtrUpKoef: double.tryParse(json['ring_atr_up_koef']?.toString() ?? '') ?? 0.0,
    );
  }
}

// TŘÍDA PRO MATERIÁLY
class MaterialItem extends BaseItem {
  final bool stackable;

  MaterialItem({
    required super.itemId,
    super.itemBaseId,
    required super.name,
    required super.description,
    required super.itemImgOzn,
    required super.itemStatus,
    required super.amount,
    required super.category,
    required super.lvlReq,
    required super.rarity,
    required super.priceKs,
    required super.priceAll,
    required super.itemLvl,
    required super.weaponDmgUpKoef,
    required super.armorArmorUpKoef,
    required super.armorHpUpKoef,
    required super.helmetArmorUpKoef,
    required super.bootsArmorUpKoef,
    required super.bootsAttackSpeedUpKoef,
    required super.amuletAtrUpKoef,
    required super.ringAtrUpKoef,
    required this.stackable,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      itemId: json['item_id'] ?? 0,
      itemBaseId: json['item_base_id'],
      name: json['name'] ?? 'Neznámý materiál',
      description: json['description'] ?? '',
      itemImgOzn: json['item_img_ozn'] ?? 'item_default',
      itemStatus: json['item_status'] ?? 'inventory',
      amount: (json['amount'] as num?)?.toInt() ?? 1, // BEZPEČNÁ KONVERZE
      category: json['category'] ?? 'material',
      lvlReq: (json['lvl_req'] as num?)?.toInt() ?? 1,
      rarity: json['rarity'] ?? 'basic',
      priceKs: (json['price_ks'] as num?)?.toInt() ?? 0,
      priceAll: (json['price_all'] as num?)?.toInt() ?? 0,
      stackable: json['stackable'] ?? true,
      itemLvl: (json['item_lvl'] as num?)?.toInt() ?? 0,
      weaponDmgUpKoef: double.tryParse(json['weapon_dmg_up_koef']?.toString() ?? '') ?? 0.0,
      armorArmorUpKoef: double.tryParse(json['armor_up_koef_ARMOR']?.toString() ?? '') ?? 0.0,
      armorHpUpKoef: double.tryParse(json['armor_up_koef_HP']?.toString() ?? '') ?? 0.0,
      helmetArmorUpKoef: double.tryParse(json['helmet_armor_up_koef']?.toString() ?? '') ?? 0.0,
      bootsArmorUpKoef: double.tryParse(json['boots_armor_up_koef']?.toString() ?? '') ?? 0.0,
      bootsAttackSpeedUpKoef: double.tryParse(json['boots_attack_speed_up_koef']?.toString() ?? '') ?? 0.0,
      amuletAtrUpKoef: double.tryParse(json['amulet_atr_up_koef']?.toString() ?? '') ?? 0.0,
      ringAtrUpKoef: double.tryParse(json['ring_atr_up_koef']?.toString() ?? '') ?? 0.0,
    );
  }
}

// ---------------------------------------------------------
// HLAVNÍ TŘÍDA PROFILU HRÁČE
// ---------------------------------------------------------
class PlayerProfile {
  // Původní proměnné hráče
  final String username;
  final int lvl;
  final int xp;
  final int xpNextLvl;
  final int gold;
  final int dungeonTokens;
  final int hpMax;
  final int manaMax;
  final int strMax;
  final int dexMax;
  final int intMax;
  final int vitMax;
  final int luckMax;
  final int precMax;
  final int dmgMin;
  final int dmgMax;
  final int armor;
  final double critChance;
  final String avatar;
  final String role;
  final String gender;
  final int energyPoints;
  final DateTime? busyUntil;
  final int steps;
  final int stepsToday;
  final int atrPoints;
  final int skillPoints;
  final String dmgAtr;
  final double attackSpeed;
  final double critMultiplier;
  final int strResist;
  final int dexResist;
  final int intResist;

  // NOVÉ: Seznamy předmětů
  final List<EqpItem> eqpItems;
  final List<MaterialItem> materialItems;

  PlayerProfile({
    required this.username,
    required this.lvl,
    required this.xp,
    required this.xpNextLvl,
    required this.gold,
    required this.dungeonTokens,
    required this.hpMax,
    required this.manaMax,
    required this.strMax,
    required this.dexMax,
    required this.intMax,
    required this.vitMax,
    required this.luckMax,
    required this.precMax,
    required this.dmgMin,
    required this.dmgMax,
    required this.armor,
    required this.critChance,
    required this.avatar,
    required this.role,
    required this.gender,
    required this.energyPoints,
    this.busyUntil,
    required this.steps,
    required this.stepsToday,
    required this.atrPoints,
    required this.skillPoints,
    required this.dmgAtr,
    required this.attackSpeed,
    required this.critMultiplier,
    required this.strResist,
    required this.dexResist,
    required this.intResist,
    required this.eqpItems,
    required this.materialItems,
  });

  // Pomocný getter: Spojí vybavení i materiály do jednoho listu pro inventář
  List<BaseItem> get allItems => [...eqpItems, ...materialItems];

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    
    // Zpracování listů z JSONu
    var eqpListJson = json['all_items_eqp_able'] as List? ?? [];
    var matListJson = json['all_items_material'] as List? ?? [];

    return PlayerProfile(
      username: json['username'] ?? 'Hrdina',
      lvl: (json['lvl'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      xpNextLvl: (json['xp_next_lvl'] as num?)?.toInt() ?? 100,
      // POZOR: Tady byl pravděpodobně problém. Gold může být 1500.5 (double)
      gold: (json['gold'] as num?)?.toInt() ?? 0, 
      dungeonTokens: (json['dungeon_tokens'] as num?)?.toInt() ?? 0,
      hpMax: (json['hp_max'] as num?)?.toInt() ?? 0,
      manaMax: (json['mana_max'] as num?)?.toInt() ?? 0,
      strMax: (json['str_max'] as num?)?.toInt() ?? 0,
      dexMax: (json['dex_max'] as num?)?.toInt() ?? 0,
      intMax: (json['int_max'] as num?)?.toInt() ?? 0,
      vitMax: (json['vit_max'] as num?)?.toInt() ?? 0,
      luckMax: (json['luck_max'] as num?)?.toInt() ?? 0,
      precMax: (json['prec_max'] as num?)?.toInt() ?? 0,
      dmgMin: (json['dmg_min'] as num?)?.toInt() ?? 0,
      dmgMax: (json['dmg_max'] as num?)?.toInt() ?? 0,
      armor: (json['armor'] as num?)?.toInt() ?? 0,
      
      // I tady mohl být problém (pokud přijde celé číslo např. 5 místo 5.0)
      critChance: (json['crit_chance'] as num?)?.toDouble() ?? 0.0,
      
      avatar: json['avatar_img_ozn'] ?? 'avatar_default', 
      role: json['role'] ?? 'Nedefinováno',
      gender: json['gender'] ?? 'Nedefinováno',
      energyPoints: (json['energy_points'] as num?)?.toInt() ?? 0,
      busyUntil: json['busy_until'] != null ? DateTime.parse(json['busy_until']) : null,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      stepsToday: (json['steps_today'] as num?)?.toInt() ?? 0,
      atrPoints: (json['atr_points'] as num?)?.toInt() ?? 0,
      skillPoints: (json['skill_points'] as num?)?.toInt() ?? 0,
      dmgAtr: json['dmg_atr'] ?? 'Nedefinovaný atribut',
      
      // Ošetření attack_speed a crit_multiplier
      attackSpeed: (json['attack_speed'] as num?)?.toDouble() ?? 0.0,
      critMultiplier: (json['crit_multiplier'] as num?)?.toDouble() ?? 0.0,
      
      strResist: (json['str_resist'] as num?)?.toInt() ?? 0,
      dexResist: (json['dex_resist'] as num?)?.toInt() ?? 0,
      intResist: (json['int_resist'] as num?)?.toInt() ?? 0,
      
      // Naplnění našich nových Listů
      eqpItems: eqpListJson.map((i) => EqpItem.fromJson(i)).toList(),
      materialItems: matListJson.map((i) => MaterialItem.fromJson(i)).toList(),
    );
  }

  // Pomocná funkce pro XP bar (0.0 až 1.0)
  double get xpProgress => (xpNextLvl > 0) ? (xp / xpNextLvl).clamp(0.0, 1.0) : 0.0;
}