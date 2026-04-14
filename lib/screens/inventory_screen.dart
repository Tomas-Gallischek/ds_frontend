import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ds_equipment_slot.dart';

class InventoryScreen extends StatelessWidget {
  final String title;
  final String filterCategory; // 'equip', 'material', 'useable'
  final List<Map<String, dynamic>> allItems;

  const InventoryScreen({
    super.key,
    required this.title,
    required this.filterCategory,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context) {
    // MAGIE FILTRACE: Zde se rozhoduje, co se zobrazí
    final filteredItems = allItems.where((item) {
      if (item['status'] != 'inventory') return false; // Musí to být v báglu

      if (filterCategory == 'equip') {
        return ['weapon', 'armor', 'helmet', 'boots', 'amulet', 'ring', 'talisman', 'pet'].contains(item['category']);
      } else if (filterCategory == 'material') {
        return item['category'] == 'material';
      } else if (filterCategory == 'useable') {
        return item['category'] == 'useable';
      }
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentGold, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/bg/bg_dungeon_steps.png'), // Uprav cestu
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withAlpha(153), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    "Tady je zatím prázdno, hrdino.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 itemy vedle sebe
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return DsEquipmentSlot(
                      itemImg: item['img'],
                      rarity: item['rarity'],
                      size: double.infinity, // V GridView si to samo vezme maximum místa
                      amount: item['amount'],
                    );
                  },
                ),
        ),
      ),
    );
  }
}