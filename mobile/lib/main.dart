import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Aucun projet Firebase configuré (pas de google-services.json /
    // GoogleService-Info.plist) : les notifications push resteront
    // indisponibles, mais le reste de l'application doit rester utilisable.
  }
  runApp(const ScoliaApp());
}
