import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/liaison/liaison_screen.dart';
import '../screens/liaison/nouveau_message_screen.dart';
import '../screens/remarques/remarques_screen.dart';
import '../screens/remarques/nouvelle_remarque_screen.dart';
import '../screens/calendrier/calendrier_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/notes/bulletin_screen.dart';
import '../screens/frais/frais_screen.dart';
import '../screens/frais/detail_frais_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profil/profil_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final authentifie = auth.estConnecte;
      final versAuth = state.matchedLocation.startsWith('/auth');
      if (!authentifie && !versAuth && state.matchedLocation != '/') return '/auth/telephone';
      if (authentifie && versAuth) return '/accueil';
      return null;
    },
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/',           builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/telephone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(telephone: state.extra as String),
      ),
      GoRoute(path: '/accueil',    builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/liaison',    builder: (_, __) => const LiaisonScreen()),
      GoRoute(path: '/liaison/nouveau', builder: (_, __) => const NouveauMessageScreen()),
      GoRoute(path: '/remarques',  builder: (_, __) => const RemarquesScreen()),
      GoRoute(path: '/remarques/nouvelle', builder: (_, state) => NouvelleRemarqueScreen(eleveId: state.extra as int?)),
      GoRoute(path: '/calendrier', builder: (_, __) => const CalendrierScreen()),
      GoRoute(path: '/notes',      builder: (_, __) => const NotesScreen()),
      GoRoute(
        path: '/notes/bulletin/:eleveId/:periodeId',
        builder: (_, state) => BulletinScreen(
          eleveId:   int.parse(state.pathParameters['eleveId']!),
          periodeId: int.parse(state.pathParameters['periodeId']!),
        ),
      ),
      GoRoute(path: '/frais',      builder: (_, __) => const FraisScreen()),
      GoRoute(
        path: '/frais/:eleveId',
        builder: (_, state) => DetailFraisScreen(eleveId: int.parse(state.pathParameters['eleveId']!)),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profil',     builder: (_, __) => const ProfilScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.uri}')),
    ),
  );
}
