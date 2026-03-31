// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  print("--- Dart skript se prave spustil ---");

  try {
    // 1. Formátování aktuálního času
    DateTime now = DateTime.now();
    String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    
    String commitMessage = "Automaticke ulozeni: $formattedDate";

    print("Pracovni slozka: ${Directory.current.path}");

    // 2. Přidání souborů (git add .)
    print("Pridavam zmeny (git add)...");
    ProcessResult addResult = Process.runSync('git', ['add', '.']);
    if (addResult.exitCode != 0) {
      throw Exception("Chyba při git add:\n${addResult.stderr}");
    }

    // 3. Commit (git commit -m "...")
    print("Vytvarim commit: $commitMessage");
    ProcessResult commitResult = Process.runSync('git', ['commit', '-m', commitMessage]);
    
    // Pokud nejsou žádné změny, Git vypíše "nothing to commit"
    if (commitResult.stdout.toString().contains("nothing to commit")) {
      print("Zadne nove zmeny k ulozeni.");
    } else {
      print(commitResult.stdout.toString().trim());
    }

    // 4. Push (git push origin main)
    print("Odesilam na GitHub (git push)...");
    ProcessResult pushResult = Process.runSync('git', ['push', 'origin', 'main']);
    if (pushResult.exitCode != 0) {
      throw Exception("Chyba při git push:\n${pushResult.stderr}");
    }

    print("✅ VSE USPESNE ULOZENO");

  } catch (e) {
    print("❌ Nastala chyba: $e");
  }
}