import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart'; // <-- ZMĚNA 1: Importujeme profile_screen místo map_screen
import 'register_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/ds_button.dart';
import '../widgets/ds_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3), 
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight.withValues(alpha: 0.6),
          ),
      prefixIcon: Icon(icon, color: AppTheme.panelWood),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.panelWood, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.textError, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.textError, width: 2),
      ),
    );
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService(); 
      
      final bool success = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            // <-- ZMĚNA 2: Přesměrování na ProfileScreen
            MaterialPageRoute(builder: (context) => const ProfileScreen()), 
          );
        }
      } else {
        setState(() {
          _errorMessage = "Neplatné jméno nebo heslo, hrdino.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Kritická chyba: Nepodařilo se spojit se serverem.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/login/bg_dungeon_steps.png',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.4), 
            colorBlendMode: BlendMode.darken,
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  const SizedBox(height: 10),
                  Text(
                    "Dungeon Steps",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 30),

                  DsPanel(
                    child: Column(
                      children: [
                        Text(
                          "Vstup do podzemí",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 25),

                        // Jméno hrdiny
                        TextFormField(
                          controller: _usernameController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: _buildInputDecoration("Jméno hrdiny", Icons.person),
                          // <-- ZMĚNA 3: Tlačítko "Další" na klávesnici
                          textInputAction: TextInputAction.next, 
                        ),
                        const SizedBox(height: 15),

                        // Heslo
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: _buildInputDecoration("Klíč (Heslo)", Icons.lock),
                          // <-- ZMĚNA 4: Tlačítko "Hotovo" na klávesnici a odeslání Enterem
                          textInputAction: TextInputAction.done, 
                          onFieldSubmitted: (_) => _login(), 
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textError),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 30),

                        if (_isLoading)
                          const CircularProgressIndicator(color: AppTheme.accentGold)
                        else
                          SizedBox(
                            width: double.infinity,
                            child: DsButton(
                              text: "Přihlásit se",
                              onPressed: _login,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Jsi tu nový?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  DsButton(
                    text: "Vytvořit hrdinu",
                    isPrimary: false,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}