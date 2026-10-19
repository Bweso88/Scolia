import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../config/theme.dart';
import '../../models/academic_event.dart';
import '../../models/attendance_record.dart';
import '../../models/homework.dart';
import '../../models/remarque.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';
import '../../services/children_service.dart';

/// Accueil — repris du mockup "Scholarly" fourni par l'utilisateur : carte
/// de bienvenue en dégradé avec climat scolaire/présence du jour, résumé de
/// la journée, prochains devoirs et agenda scolaire, sous l'en-tête et la
/// barre de navigation partagés (AppHeader/BottomNav).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _childrenService = ChildrenService();
  Map<String, dynamic>? _dashboard;
  List<Homework> _devoirsAVenir = [];
  bool _chargeDashboard = false;
  int? _dernierEnfantCharge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    context.read<NotificationsProvider>().charger();

    final user = context.read<AuthProvider>().user;
    if (user?.estParent != true) return;

    final enfants = context.read<ChildProvider>();
    await enfants.charger();
    await _chargerDashboard();
  }

  Future<void> _chargerDashboard() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() => _chargeDashboard = true);
    try {
      final resultats = await Future.wait([
        _childrenService.getDashboard(enfant.id),
        _childrenService.getDevoirs(enfant.id, range: 'week'),
      ]);
      setState(() {
        _dashboard = resultats[0] as Map<String, dynamic>;
        _devoirsAVenir = (resultats[1] as List<Homework>).take(2).toList();
        _dernierEnfantCharge = enfant.id;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargeDashboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    final enfantCourant = context.watch<ChildProvider>().selectionne;
    if (user?.estParent == true && enfantCourant != null && enfantCourant.id != _dernierEnfantCharge && !_chargeDashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerDashboard());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _charger,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: AppHeader.hauteur + 12, bottom: 16),
              children: [
                if (user?.estParent == true) ..._sectionParent(context, user),
                if (user?.faitPartieDuPersonnel == true) ..._sectionPersonnel(context, user),
              ],
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: AppHeader()),
        ],
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 0),
    );
  }

  // --- Dérivés depuis les données déjà chargées (aucune donnée inventée) ---

  ({IconData icone, String libelle}) _climatDuJour(List<Remarque> obs) {
    if (obs.any((o) => o.category == 'incident')) {
      return (icone: Icons.cloud_outlined, libelle: 'Journée difficile');
    }
    if (obs.any((o) => o.category == 'discipline')) {
      return (icone: Icons.filter_drama_outlined, libelle: 'Journée à surveiller');
    }
    if (obs.any((o) => o.category == 'positive' || o.category == 'participation')) {
      return (icone: Icons.wb_sunny_outlined, libelle: 'Journée calme & sereine');
    }
    return (icone: Icons.wb_cloudy_outlined, libelle: 'Journée normale');
  }

  ({String libelle, Color couleur, IconData icone}) _presenceDuJour(List<AttendanceRecord> records) {
    final aujourdHui = DateFormat('yyyy-MM-dd').format(DateTime.now());
    AttendanceRecord? record;
    for (final r in records) {
      if (r.date == aujourdHui) { record = r; break; }
    }
    if (record == null) return (libelle: 'Présent', couleur: AppColors.green, icone: Icons.check_circle_outline);
    if (record.estAbsence) return (libelle: 'Absent', couleur: AppColors.red, icone: Icons.cancel_outlined);
    return (libelle: 'Retard', couleur: AppColors.amber, icone: Icons.schedule_outlined);
  }

  List<Widget> _sectionParent(BuildContext context, dynamic user) {
    final enfants = context.watch<ChildProvider>();

    if (enfants.charge && enfants.enfants.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))];
    }
    if (enfants.enfants.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: EmptyState(
            message: 'Aucun enfant lié',
            sousTitre: 'Contactez l\'école pour activer votre compte parent.',
            icone: Icons.child_care_outlined,
          ),
        ),
      ];
    }

    final enfant = enfants.selectionne;
    final dashboard = _dashboard;

    if (_chargeDashboard && dashboard == null) {
      return [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ChildSelector()),
        const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (dashboard == null) {
      return [const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ChildSelector())];
    }

    final homeworksJour = (dashboard['homeworks_today'] as List? ?? []).map((e) => Homework.fromJson(e as Map<String, dynamic>)).toList();
    final observations = (dashboard['recent_behavior'] as List? ?? []).map((e) => Remarque.fromJson(e as Map<String, dynamic>)).toList();
    final presences = (dashboard['recent_attendance'] as List? ?? []).map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
    final evenements = (dashboard['next_events'] as List? ?? []).map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>)).toList();
    final tenant = user?.tenant;

    final climat = _climatDuJour(observations);
    final presence = _presenceDuJour(presences);
    final nbDevoirs = homeworksJour.length;

    final sousTitre = nbDevoirs == 0
        ? (climat.libelle == 'Journée calme & sereine'
            ? '${enfant?.firstName ?? "Votre enfant"} passe une excellente journée !'
            : 'Aujourd\'hui, tout se passe pour le mieux à l\'école.')
        : '$nbDevoirs devoir${nbDevoirs > 1 ? 's' : ''} à préparer pour aujourd\'hui.';

    return [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ChildSelector()),
      const SizedBox(height: 16),
      AnimatedEntry(
        index: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _carteHero(tenant?.displayName, user?.name, sousTitre, climat, presence),
        ),
      ),
      const SizedBox(height: 24),
      _enTeteSection('Résumé de la journée', badge: 'AUJOURD\'HUI'),
      const SizedBox(height: 10),
      AnimatedEntry(
        index: 1,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _carteResume(observations)),
      ),
      const SizedBox(height: 24),
      _enTeteSection(
        'Prochains devoirs',
        sousTitre: nbDevoirs > 0 ? '($nbDevoirs en attente)' : null,
        action: ('Voir tout', () => context.go('/devoirs')),
      ),
      const SizedBox(height: 10),
      if (_devoirsAVenir.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _cartePlate('Aucun devoir à venir cette semaine.', Icons.assignment_turned_in_outlined),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _devoirsAVenir.asMap().entries.map((entry) {
              final i = entry.key;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == _devoirsAVenir.length - 1 ? 0 : 10),
                  child: AnimatedEntry(index: i + 2, child: _carteDevoirAVenir(entry.value)),
                ),
              );
            }).toList(),
          ),
        ),
      const SizedBox(height: 24),
      _enTeteSection('Événements & Rappels', action: ('Agenda scolaire', () => context.go('/agenda'))),
      const SizedBox(height: 10),
      if (evenements.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _cartePlate('Aucun événement à venir pour l\'instant.', Icons.event_available_outlined),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: evenements.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: EdgeInsets.only(bottom: i == evenements.length - 1 ? 0 : 10),
                child: AnimatedEntry(index: i + 4, child: _carteEvenement(entry.value)),
              );
            }).toList(),
          ),
        ),
      const SizedBox(height: 28),
      _enTeteSection('Accès rapide'),
      const SizedBox(height: 12),
      _grilleAcces(context, [
        (Icons.dynamic_feed_outlined, 'Fil d\'actualité', AppColors.purple, () => context.push('/fil-actualite')),
        (Icons.event_busy_outlined, 'Absences', AppColors.orange, () => context.push('/absences')),
        (Icons.bar_chart_outlined, 'Notes', AppColors.green, () => context.push('/notes')),
        (Icons.schedule_outlined, 'Emploi du temps', AppColors.amber, () => context.push('/calendrier')),
        (Icons.payments_outlined, 'Paiement', AppColors.blue, () => context.push('/paiement')),
      ]),
    ];
  }

  List<Widget> _sectionPersonnel(BuildContext context, dynamic user) {
    final estAdmin = user?.estAdmin == true;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _cartePlate('Prêt(e) pour une nouvelle journée à l\'école ?', Icons.wb_sunny_outlined),
      ),
      const SizedBox(height: 24),
      _enTeteSection('Accès rapide'),
      const SizedBox(height: 12),
      _grilleAcces(context, [
        (Icons.groups_outlined, 'Ma classe', AppColors.blue, () => context.push('/teacher/ma-classe')),
        (Icons.assignment_outlined, 'Devoirs', AppColors.purple, () => context.go('/devoirs')),
        (Icons.bar_chart_outlined, 'Notes', AppColors.green, () => context.push('/notes')),
        (Icons.event_busy_outlined, 'Absences', AppColors.orange, () => context.push('/absences')),
        (Icons.schedule_outlined, 'Emploi du temps', AppColors.amber, () => context.push('/calendrier')),
        if (estAdmin) (Icons.admin_panel_settings_outlined, 'Gestion', AppColors.blue, () => context.push('/gestion')),
      ]),
    ];
  }

  Widget _enTeteSection(String titre, {String? sousTitre, String? badge, (String, VoidCallback)? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
                if (sousTitre != null) ...[
                  const SizedBox(width: 6),
                  Flexible(child: Text(sousTitre, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted))),
                ],
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue, letterSpacing: 0.3)),
            ),
          if (action != null)
            GestureDetector(
              onTap: action.$2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action.$1, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue)),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.blue),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _carteHero(String? ecole, String? nom, String sousTitre, ({IconData icone, String libelle}) climat, ({String libelle, Color couleur, IconData icone}) presence) {
    final prenom = (nom ?? '').split(' ').first;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ecole != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('En direct • $ecole', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
              ]),
            ),
          const SizedBox(height: 14),
          Row(children: [
            Flexible(child: Text('Bonjour $prenom', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            const Text('✨', style: TextStyle(fontSize: 20)),
          ]),
          const SizedBox(height: 6),
          Text(sousTitre, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.white.withOpacity(0.88), height: 1.35)),
          const SizedBox(height: 16),
          Divider(color: AppColors.white.withOpacity(0.2), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(climat.icone, color: AppColors.white.withOpacity(0.9), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLIMAT SCOLAIRE', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white.withOpacity(0.65), letterSpacing: 0.5)),
                    Text(climat.libelle, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(presence.icone, size: 14, color: AppColors.white),
                  const SizedBox(width: 5),
                  Text(presence.libelle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _styleObservation = {
    'positive':      (couleur: AppColors.green, icone: Icons.sentiment_very_satisfied_rounded, libelle: 'Positif'),
    'participation': (couleur: AppColors.green, icone: Icons.sentiment_satisfied_rounded, libelle: 'Participation'),
    'discipline':    (couleur: AppColors.purple, icone: Icons.edit_note_rounded, libelle: 'Discipline'),
    'incident':      (couleur: AppColors.red, icone: Icons.report_outlined, libelle: 'Incident'),
    'note_generale': (couleur: AppColors.blue, icone: Icons.comment_outlined, libelle: 'Observation'),
  };

  Widget _carteResume(List<Remarque> observations) {
    if (observations.isEmpty) {
      return _cartePlate('Aucune observation enregistrée aujourd\'hui pour l\'instant.', Icons.visibility_outlined);
    }
    final obs = observations.first;
    final style = _styleObservation[obs.category] ?? _styleObservation['note_generale']!;
    String heure = '';
    try {
      if (obs.occurredAt != null) heure = DateFormat('HH:mm').format(DateTime.parse(obs.occurredAt!));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: style.couleur.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(style.icone, color: style.couleur, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(obs.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    if (heure.isNotEmpty) Text(heure, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
                if (obs.description != null && obs.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(obs.description!, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.body, height: 1.4)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: style.couleur.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(style.libelle, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: style.couleur)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _paletteMatieres = [AppColors.green, AppColors.purple, Color(0xFF0891B2), AppColors.amber, Color(0xFFE11D48), AppColors.blue];

  Color _couleurMatiere(String? nom) {
    if (nom == null || nom.isEmpty) return AppColors.blue;
    final hash = nom.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _paletteMatieres[hash % _paletteMatieres.length];
  }

  String _etiquetteEcheance(String? dueDateStr) {
    if (dueDateStr == null) return '';
    try {
      final due = DateTime.parse(dueDateStr);
      final today = DateTime.now();
      final diff = DateTime(due.year, due.month, due.day).difference(DateTime(today.year, today.month, today.day)).inDays;
      if (diff == 0) return 'Aujourd\'hui';
      if (diff == 1) return 'Demain';
      final jour = DateFormat('EEEE', 'fr_FR').format(due);
      return jour[0].toUpperCase() + jour.substring(1);
    } catch (_) {
      return '';
    }
  }

  Widget _carteDevoirAVenir(Homework devoir) {
    final couleur = _couleurMatiere(devoir.subjectName);
    return GestureDetector(
      onTap: () => context.go('/devoirs'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.menu_book_outlined, color: couleur, size: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                  child: Text(_etiquetteEcheance(devoir.dueDate), style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text((devoir.subjectName ?? '').toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: couleur, letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(devoir.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(devoir.estFait ? 'Fait' : 'À faire', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                Text(devoir.estFait ? '100%' : '0%', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: devoir.estFait ? 1 : 0,
                minHeight: 5,
                backgroundColor: AppColors.light,
                valueColor: AlwaysStoppedAnimation(devoir.estFait ? AppColors.green : couleur),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _couleursCategorieEvenement = {
    'vacances': AppColors.green,
    'examen': Color(0xFFE11D48),
    'evenement': AppColors.blue,
    'reunion': AppColors.purple,
    'autre': AppColors.muted,
  };

  Widget _carteEvenement(AcademicEvent event) {
    final couleur = _couleursCategorieEvenement[event.category] ?? AppColors.muted;
    DateTime? debut;
    try { debut = DateTime.parse(event.startDate); } catch (_) {}

    return GestureDetector(
      onTap: () => context.go('/agenda'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: couleur, width: 3)),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            if (debut != null)
              Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: couleur.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('MMM', 'fr_FR').format(debut).toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: couleur)),
                    Text('${debut.day}', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: couleur)),
                  ],
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (event.description != null && event.description!.isNotEmpty)
                    Text(event.description!, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _cartePlate(String texte, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icone, color: AppColors.blue, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.muted))),
        ],
      ),
    );
  }

  Widget _grilleAcces(BuildContext context, List<(IconData, String, Color, VoidCallback)> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: items.asMap().entries.map((entry) {
          final (icone, titre, couleur, onTap) = entry.value;
          return AnimatedEntry(index: entry.key, child: _CarteAcces(icone: icone, titre: titre, couleur: couleur, onTap: onTap));
        }).toList(),
      ),
    );
  }
}

class _CarteAcces extends StatefulWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteAcces({required this.icone, required this.titre, required this.couleur, required this.onTap});

  @override
  State<_CarteAcces> createState() => _CarteAccesState();
}

class _CarteAccesState extends State<_CarteAcces> {
  double _echelle = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _echelle = 0.96),
      onTapCancel: () => setState(() => _echelle = 1),
      onTapUp: (_) => setState(() => _echelle = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _echelle,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: widget.couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icone, color: widget.couleur, size: 21),
              ),
              const SizedBox(height: 8),
              Text(widget.titre, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.body)),
            ],
          ),
        ),
      ),
    );
  }
}
