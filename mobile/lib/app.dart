import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/child_provider.dart';
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
        ChangeNotifierProxyProvider<AuthProvider, ChildProvider>(
          create: (_) => ChildProvider(),
          update: (_, auth, enfants) => enfants!..mettreAJourToken(auth.token),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          // Couleurs de l'école connectée appliquées à l'ensemble de
          // l'application (docs/PRODUCT_ARCHITECTURE.md §16) ; à défaut
          // (avant connexion), l'identité visuelle Scolia par défaut.
          final branding = context.watch<AuthProvider>().user?.tenant;
          return MaterialApp.router(
            title: branding?.displayName ?? 'Scolia',
            theme: buildTheme(primary: branding?.primaryColor, secondary: branding?.secondaryColor),
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr', 'FR'),
          );
        },
      ),
    );
  }
}
