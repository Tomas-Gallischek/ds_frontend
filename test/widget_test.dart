import 'package:flutter_test/flutter_test.dart';

// Import tvého hlavního souboru
import 'package:ds_frontend/main.dart'; 

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Zde jsme nahradili původní MyApp() za naši novou třídu
    await tester.pumpWidget(const DungeonStepsApp());

    // Původní test na počítadlo jsme odstranili, protože naše aplikace
    // už vypadá jinak. Tento test nyní jen zkontroluje, že se aplikace 
    // úspěšně spustí bez pádů.
  });
}