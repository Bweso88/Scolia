import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/liaison_provider.dart';
import 'providers/remarques_provider.dart';
import 'providers/evenements_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/frais_provider.dart';
import 'services/notification_service.dart';

class ScoliaApp extends StatefulWidget {
  const ScoliaApp({super.key});

  @override
  State<ScoliaApp> createState() => _ScoliaAppState();
}

class _ScoliaAppState extends State<ScoliaApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.initialiser();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, LiaisonProvider>(
          create: (_) => LiaisonProvider(),
          update: (_, auth, liaison) => liaison!..mettreAJourToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RemarquesProvider>(
          create: (_) => RemarquesProvider(),
          update: (_, auth, rq) => rq!..mettreAJourToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EvenementsProvider>(
          create: (_) => EvenementsProvider(),
          update: (_, auth, ev) => ev!..mettreAJourToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotesProvider>(
          create: (_) => NotesProvider(),
          update: (_, auth, notes) => notes!..mettreAJourToken(auth.token),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FraisProvider>(
          create: (_) => FraisProvider(),
          update: (_, auth, frais) => frais!..mettreAJourToken(auth.token),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'Scolia',
            theme: buildTheme(),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr', 'FR'),
          );
        },
      ),
    );
  }
}
