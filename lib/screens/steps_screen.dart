import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/ds_panel.dart';
import 'profile_screen.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _todaysSteps = 0;
  bool _isLoading = true;
  String _statusText = "Vyvolávám spojení s Health API...";

  @override
  void initState() {
    super.initState();
    _fetchTodaySteps();
  }

  Future<void> _fetchTodaySteps() async {
    setState(() {
      _isLoading = true;
      _statusText = "Ověřuji povolení senzorů...";
    });

    try {
      var activityStatus = await Permission.activityRecognition.request();
      if (activityStatus.isDenied) {
        setState(() {
          _statusText = "Bez povolení senzorů nepoznám, že kráčíš!";
          _isLoading = false;
        });
        return;
      }

      // OPRAVA: Odstraněn parametr. Health Connect je teď nativní a povinný.
      Health().configure();
      
      final types = [HealthDataType.STEPS];

      bool hasPermissions = await Health().hasPermissions(types) ?? false;
      if (!hasPermissions) {
        setState(() {
          _statusText = "Čekám na schválení přístupu k datům...";
        });
        hasPermissions = await Health().requestAuthorization(types);
      }

      if (hasPermissions) {
        setState(() {
          _statusText = "Sčítám tvé dnešní kroky...";
        });
        
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        
        int? steps = await Health().getTotalStepsInInterval(midnight, now);
        
        setState(() {
          _todaysSteps = steps ?? 0;
          _statusText = "Kroky úspěšně přečteny z kroniky!";
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusText = "Přístup ke krokům byl zamítnut.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusText = "NA TOMTO ZAŘÍZENÍ NENÍ PODPOROVÁNO ZÍSKÁVÁNÍ KROKŮ.";
        _isLoading = false;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentGold, size: 28),
          onPressed: () {
            // BEZPEČNOSTNÍ POJISTKA
            if (Navigator.canPop(context)) {
              // Pokud je v historii předchozí obrazovka, prostě se vrátíme
              Navigator.pop(context);
            } else {
              // Pokud jsme na konci stacku (hrozila by černá obrazovka),
              // pošleme hráče natvrdo zpět na profil.
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          },
        ),
        title: Text("Magické zrcadlo kroků", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: DsPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Dnešní výprava",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 30),
                
                if (_isLoading)
                  const CircularProgressIndicator(color: AppTheme.stepsGreen)
                else
                  Text(
                    "$_todaysSteps",
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 72,
                      color: AppTheme.stepsGreen,
                    ),
                  ),
                  
                const SizedBox(height: 10),
                Text(
                  "Kroků",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                
                const SizedBox(height: 40),
                
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _isLoading ? AppTheme.accentGold : AppTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}