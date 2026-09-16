import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/selection_ecole_screen.dart';
import '../screens/devoirs/devoirs_screen.dart';
import '../screens/devoirs/publier_devoir_screen.dart';
import '../screens/absences/absences_screen.dart';
import '../screens/absences/saisir_absence_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/liaison/liaison_screen.dart';
import '../screens/liaison/nouveau_message_screen.dart';
import '../screens/remarques/remarques_screen.dart';
import '../screens/remarques/nouvelle_remarque_screen.dart';
import '../screens/calendrier/calendrier_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profil/profil_screen.dart';
import '../screens/profil/preferences_notifications_screen.dart';
import '../screens/teacher/ma_classe_screen.dart';
import '../screens/notes/saisir_note_screen.dart';

GoRouter buildRouter(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context, listen: false);

  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final authentifie = auth.estConnecte;
      final versAuth    = state.matchedLocation.startsWith('/auth');
      if (!authentifie && !versAuth && state.matchedLocation != '/') return '/auth/connexion';
      // '/auth/ecole' reste accessible authentifié : c'est l'étape de
      // bascule entre écoles pour un parent multi-établissements.
      if (authentifie && versAuth && state.matchedLocation != '/auth/ecole') return '/accueil';
      return null;
    },
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/',                  builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/connexion',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/ecole',        builder: (_, __) => const SelectionEcoleScreen()),
      GoRoute(path: '/accueil',           builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/devoirs',           builder: (_, __) => const DevoirsScreen()),
      GoRoute(path: '/devoirs/publier',   builder: (_, __) => const PublierDevoirScreen()),
      GoRoute(path: '/absences',          builder: (_, __) => const AbsencesScreen()),
      GoRoute(
        path: '/absences/saisir',
        builder: (_, state) => SaisirAbsenceScreen(eleveId: state.extra as int?),
      ),
      GoRoute(path: '/liaison',           builder: (_, __) => const LiaisonScreen()),
      GoRoute(path: '/liaison/nouveau',   builder: (_, __) => const NouveauMessageScreen()),
      GoRoute(path: '/remarques',         builder: (_, __) => const RemarquesScreen()),
      GoRoute(
        path: '/remarques/nouvelle',
        builder: (_, state) => NouvelleRemarqueScreen(eleveId: state.extra as int?),
      ),
      GoRoute(path: '/calendrier',        builder: (_, __) => const CalendrierScreen()),
      GoRoute(path: '/notes',             builder: (_, __) => const NotesScreen()),
      GoRoute(
        path: '/notes/saisir',
        builder: (_, state) => SaisirNoteScreen(eleveId: state.extra as int?),
      ),
      GoRoute(path: '/notifications',     builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profil',            builder: (_, __) => const ProfilScreen()),
      GoRoute(path: '/profil/notifications', builder: (_, __) => const PreferencesNotificationsScreen()),
      GoRoute(path: '/teacher/ma-classe', builder: (_, __) => const MaClasseScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.uri}')),
    ),
  );
}
