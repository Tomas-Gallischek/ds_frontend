import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DungeonStepsApp());
}

class DungeonStepsApp extends StatelessWidget {
  const DungeonStepsApp({super.key}); // <-- Změna zde: super parametr

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dungeon Steps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, 
      home: const LoginScreen(),
    );
  }
}