import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'package:ds_frontend/screens/profile_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Ovládání textových polí
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false; // Pro zobrazení načítacího kolečka
  String? _errorMessage; // Pro zobrazení chybové hlášky

  // Funkce, která se spustí po kliknutí na tlačítko "Přihlásit se"
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Vyplň prosím jméno i heslo.';
        _isLoading = false;
      });
      return;
    }

    // Volání na backend přes naši službu
    final success = await _apiService.login(username, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      debugPrint("Úspěšně přihlášeno, token je uložen!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přihlášení proběhlo úspěšně!')),
      );

      // Nahradíme aktuální obrazovku ProfileScreenem.
      // Používáme pushReplacement, aby se uživatel nemohl tlačítkem "Zpět"
      // na Androidu vrátit na přihlašovací obrazovku, když už je přihlášený.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Špatné přihlašovací údaje nebo server neodpovídá.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Dungeon Steps',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              
              // Textové pole pro uživatelské jméno
              TextField(
                controller: _usernameController,
                textInputAction: TextInputAction.next, // Při stisku Enteru přejde na další pole (heslo)
                decoration: const InputDecoration(
                  labelText: 'Uživatelské jméno',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Textové pole pro heslo
              TextField(
                controller: _passwordController,
                obscureText: true, // Skryje heslo pod tečky
                textInputAction: TextInputAction.done, // Klávesa Enter bude fungovat jako "Hotovo"
                onSubmitted: (_) => _handleLogin(), // Spustí přihlášení po stisku Enteru
                decoration: const InputDecoration(
                  labelText: 'Heslo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              
              // Zobrazení případné chyby
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Tlačítko přihlášení nebo načítací kolečko
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Přihlásit se', style: TextStyle(fontSize: 18)),
                    ), // Zde končí první dílek čárkou

              // 2. DÍLEK: Mezera
              const SizedBox(height: 16),
              
              // 3. DÍLEK: Tlačítko pro přechod na registraci
              TextButton(
                onPressed: () {
                  // Navigace na novou obrazovku
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Nemáš účet? Vytvoř si hrdinu!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Vždy je dobré po sobě uklidit controllery, aby nedocházelo k úniku paměti
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}