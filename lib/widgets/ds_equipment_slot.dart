import 'package:flutter/material.dart';

class DsEquipmentSlot extends StatelessWidget {
  final String? itemImg;
  final String rarity;
  final double size;

  const DsEquipmentSlot({
    super.key,
    this.itemImg,
    this.rarity = 'basic',
    this.size = 85,
  });

  @override
  Widget build(BuildContext context) {
    String framePath = 'assets/efects/basic_frame.png';
    if (rarity == 'rare') framePath = 'assets/efects/rare_frame.png';
    if (rarity == 'epic') framePath = 'assets/efects/epic_frame.png';
    if (rarity == 'legendary') framePath = 'assets/efects/legendary_frame.png';

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(102), // 0.4 opacity
              borderRadius: BorderRadius.circular(size * 0.1),
            ),
          ),
          if (itemImg != null)
            Image.asset(itemImg!, width: size * 0.7, height: size * 0.7, fit: BoxFit.contain),
          Image.asset(framePath, width: size, height: size, fit: BoxFit.cover),
        ],
      ),
    );
  }
}