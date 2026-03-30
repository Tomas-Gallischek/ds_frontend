import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DungeonStepsApp());
}

class DungeonStepsApp extends StatelessWidget {
  const DungeonStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dungeon Steps',
      debugShowCheckedModeBanner: false, // Skryje ten otravný "DEBUG" nápis vpravo nahoře
      theme: ThemeData(
        // Tady později nasadíme tvůj připravený vizuální styl
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Zatím zde dáme jen zástupnou obrazovku, v dalším kroku ji nahradíme Loginem
      home: const LoginScreen(),
    );
  }
}