import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'map_screen.dart';
import 'register_screen.dart';
// Importujeme naše nové styly a widgety
import '../theme/app_theme.dart';
import '../widgets/ds_button.dart';
import '../widgets/ds_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Opraveno na super.key

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Pomocná metoda pro stylování vstupních polí (InputDecoration)
  // Abychom ji nemuseli psát dvakrát
  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3), // Tmavé pozadí pole
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textLight.withValues(alpha: 0.6),
          ),
      prefixIcon: Icon(icon, color: AppTheme.panelWood),
      // Ohraničení v klidovém stavu (dřevěná barva)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.panelWood, width: 1.5),
      ),
      // Ohraničení při kliknutí (zlatá barva)
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.accentGold, width: 2),
      ),
      // Ohraničení při chybě
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
      // 1. Vytvoříme instanci ApiService
      final apiService = ApiService(); 
      
      // 2. Voláme login, který vrací bool (true pokud se to povedlo, false pokud ne)
      // ApiService se sám postará o uložení tokenu do SharedPreferences
      final bool success = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        }
      } else {
        // Pokud backend vrátí false (špatné heslo atd.)
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
      // ScaffoldBackgroundColor je už nastaven v Theme na AppTheme.bgDark
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Obrázek na pozadí z původního kódu
          // Přidáme mu trochu ztmavení, aby text lépe vynikl
          Image.asset(
              'assets/login/bg_dungeon_steps.png', // Nová cesta
              fit: BoxFit.cover,
              // Možná budeš muset mírně upravit ztmavení (alpha),
              // podle toho, jak čitelné budou texty.
              color: Colors.black.withValues(alpha: 0.7), 
              colorBlendMode: BlendMode.darken,
            ),

          // 2. Obsah obrazovky
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

                  // --- PŘIHLAŠOVACÍ FORMULÁŘ V DS PANELU ---
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
                        ),
                        const SizedBox(height: 15),

                        // Heslo
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: _buildInputDecoration("Klíč (Heslo)", Icons.lock),
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

                        // Tlačítko Přihlásit se (DsButton)
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

                  // Tlačítko pro registraci (Sekundární DsButton)
                  Text(
                    "Jsi tu nový?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  DsButton(
                    text: "Vytvořit hrdinu",
                    isPrimary: false, // Bude dřevěné, ne zlaté
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