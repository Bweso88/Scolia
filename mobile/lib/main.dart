import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Requis par tous les DateFormat(..., 'fr_FR') de l'app (devoirs,
  // comportement, absences, annonces...) — sans ça, chaque écran qui
  // affiche une date lève une LocaleDataException au build.
  await initializeDateFormatting('fr_FR');
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Aucun projet Firebase configuré (pas de google-services.json /
    // GoogleService-Info.plist) : les notifications push resteront
    // indisponibles, mais le reste de l'application doit rester utilisable.
  }
  runApp(const ScoliaApp());
}
