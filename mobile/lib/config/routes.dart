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
import '../screens/messagerie/messagerie_screen.dart';
import '../screens/messagerie/nouvelle_conversation_screen.dart';
import '../screens/messagerie/conversation_screen.dart';
import '../screens/gestion/gestion_screen.dart';
import '../screens/gestion/matieres_screen.dart';
import '../screens/gestion/classes_screen.dart';
import '../screens/gestion/creer_classe_screen.dart';
import '../screens/gestion/professeurs_screen.dart';
import '../screens/gestion/creer_professeur_screen.dart';
import '../screens/gestion/eleves_gestion_screen.dart';
import '../screens/gestion/creer_eleve_screen.dart';
import '../models/school_class_admin.dart';
import '../models/teacher_admin.dart';
import '../models/student.dart';
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
      GoRoute(path: '/messagerie',           builder: (_, __) => const MessagerieScreen()),
      GoRoute(path: '/messagerie/nouvelle',  builder: (_, __) => const NouvelleConversationScreen()),
      GoRoute(
        path: '/messagerie/conversation',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ConversationScreen(conversationId: extra['id'] as int, titre: extra['titre'] as String);
        },
      ),
      GoRoute(path: '/gestion',              builder: (_, __) => const GestionScreen()),
      GoRoute(path: '/gestion/matieres',      builder: (_, __) => const MatieresScreen()),
      GoRoute(path: '/gestion/classes',       builder: (_, __) => const ClassesScreen()),
      GoRoute(
        path: '/gestion/classes/creer',
        builder: (_, state) => CreerClasseScreen(classe: state.extra as SchoolClassAdmin?),
      ),
      GoRoute(path: '/gestion/professeurs',   builder: (_, __) => const ProfesseursScreen()),
      GoRoute(
        path: '/gestion/professeurs/creer',
        builder: (_, state) => CreerProfesseurScreen(professeur: state.extra as TeacherAdmin?),
      ),
      GoRoute(path: '/gestion/eleves',        builder: (_, __) => const ElevesGestionScreen()),
      GoRoute(
        path: '/gestion/eleves/creer',
        builder: (_, state) => CreerEleveScreen(eleve: state.extra as Student?),
      ),
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
