import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Přidáno pro debugPrint

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  // --- LOGIN ---
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login_view/'); // Upraveno dle tvého views.py
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          await _saveToken(data['token']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Chyba při přihlašování: $e');
      return false;
    }
  }

  // --- REGISTRACE ---
  Future<bool> register(String username, String password, String email, String role, String gender) async {
    final url = Uri.parse('$baseUrl/registrace/');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'role': role,
          'gender': gender,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          await _saveToken(data['token']); // Rovnou hráče přihlásíme
          return true;
        }
      } else {
        debugPrint('Chyba registrace (Backend vrátil): ${response.body}');
      }
      return false;
    } catch (e) {
      debugPrint('Chyba při registraci: $e');
      return false;
    }
  }

  // Uložení a načtení tokenu (zůstává stejné)
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // --- ZÍSKÁNÍ PROFILU ---
  Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    
    // Pokud token nemáme, uživatel není přihlášen
    if (token == null) {
      debugPrint('Žádný token nenalezen.');
      return null; 
    }

    final url = Uri.parse('$baseUrl/profile/'); // Cesta k tvému view v Djangu
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          // Takto se posílá ověření u Django REST Frameworku
          'Authorization': 'Token $token', 
        },
      );

      if (response.statusCode == 200) {
        // Převedeme JSON text z backendu na Dart Map (slovník)
        return jsonDecode(response.body); 
      } else {
        debugPrint('Chyba načítání profilu: Backend vrátil kód ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Chyba při stahování profilu: $e');
      return null;
    }
  }


// --- NASAZOVÁNÍ A SUNDÁVÁNÍ PŘEDMĚTŮ ---
  Future<bool> toggleEquip(int itemId, String itemName, String newStatus) async {
    final token = await getToken();
    
    if (token == null) {
      debugPrint('Žádný token nenalezen, uživatel není přihlášen.');
      return false;
    }

    final url = Uri.parse('$baseUrl/toggle_equip/'); // Tvůj nový endpoint
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'item_id': itemId,
          'item_name': itemName,
          'new_status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Vybavení úspěšně změněno.');
        return true;
      } else {
        debugPrint('Chyba při změně vybavení: Backend vrátil kód ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Kritická chyba při volání toggle_equip: $e');
      return false;
    }
  }

// --- ZVYŠOVÁNÍ ATRIBUTŮ ---
  Future<bool> addAtr(Map<String, int> updates) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/add_atr/'); 
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'updates': updates // Backend přesně tohle očekává
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Chyba přidávání atributů: Backend vrátil kód ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Kritická chyba při volání add_atr: $e');
      return false;
    }
  }

// ==========================================
  // --- OBCHOD A INVENTÁŘ ---
  // ==========================================

  // 1. Načtení nabídky obchodu
  Future<List<dynamic>?> getShopItems() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/shop/'); // Z tvého shop_screen.py
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Token $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['items_in_shop']; // Odpovídá úpravě ve tvém Python kódu
      }
      return null;
    } catch (e) {
      debugPrint('Chyba při načítání obchodu: $e');
      return null;
    }
  }

  // 2. Nákup předmětu
  Future<bool> buyItem(int itemId, String itemName, dynamic itemPrice) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/shop_buy/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({'item_id': itemId, 'item_name': itemName, 'item_price': itemPrice}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// Změněno: Přidán parametr int amount
  Future<bool> sellItem(int itemId, String itemName, dynamic itemPrice, int amount) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/sell_item/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
        body: jsonEncode({
          'item_id': itemId, 
          'item_name': itemName, 
          'item_price': itemPrice,
          'amount': amount // ZMĚNĚNO: Posíláme množství
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. Obnova (Refresh) obchodu za goldy
  Future<bool> refreshShop() async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/shop_refresh/');
    try {
      // Refresh u tebe nepotřebuje posílat tělo (body), jen prázdný POST
      final response = await http.post(url, headers: {'Authorization': 'Token $token'});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// ==========================================
  // --- LOKACE A DUNGEONY ---
  // ==========================================

  // Stažení detailů konkrétního dungeonu podle ID
  Future<Map<String, dynamic>?> getDungeonDetails(int dungeonId) async {
    final token = await getToken();
    if (token == null) return null;

    // Tento endpoint v Djangu pak připravíš tak, aby vracel detaily (název, pozadí, dropy)
    final url = Uri.parse('$baseUrl/dungeon/$dungeonId/'); 
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Token $token'});
      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      }
      return null;
    } catch (e) {
      debugPrint('Chyba při načítání dungeonu: $e');
      return null;
    }
  }

// --- INICIALIZACE SOUBOJE ---
  Future<bool> initFight(int dungeonBaseId) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/init_fight/');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Token $token' // Zde tě backend identifikuje
        },
        body: jsonEncode({
          'dungeon_base_id': dungeonBaseId
        }),
      );
      
      // Předpokládáme, že úspěšná inicializace vrátí kód 200 (OK)
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Chyba při inicializaci souboje: $e');
      return false;
    }
  }


}