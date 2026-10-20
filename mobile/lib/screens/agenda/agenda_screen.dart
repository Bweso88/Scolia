import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/academic_event.dart';
import '../../models/announcement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/academic_event_service.dart';
import '../../services/announcement_service.dart';
import '../../services/children_service.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/app_header.dart';
import '../../widgets/archivable_tile.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';

/// Palette propre à cet écran, reprise du mockup fourni ("Calendrier &
/// Annonces") — même famille de bleus que l'écran de connexion.
class _Ag {
  static const primary = Color(0xFF2563EB);
  static const primaryDim = Color(0xFF1D4ED8);
  static const primaryContainer = Color(0xFFDBEAFE);
  static const secondary = Color(0xFF10B981);
  static const secondaryContainer = Color(0xFFD1FAE5);
  static const tertiary = Color(0xFF8B5CF6);
  static const tertiaryContainer = Color(0xFFEDE9FE);
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF64748B);
  static const outline = Color(0xFFCBD5E1);
  static const outlineVariant = Color(0xFFE2E8F0);
}

enum _Filtre { tous, annonces, evenements }

/// Fusionne les annonces de l'école et le calendrier des événements à venir
/// (docs/PRODUCT_ARCHITECTURE.md — écran "Agenda"), repris du design fourni
/// par l'utilisateur. Remplace les anciens écrans Annonces/Calendrier dans
/// la barre de navigation (l'emploi du temps hebdomadaire reste accessible
/// séparément depuis l'accueil).
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _childrenService = ChildrenService();
  final _announcementService = AnnouncementService();
  final _eventService = AcademicEventService();

  List<Announcement> _annonces = [];
  List<AcademicEvent> _evenements = [];
  bool _charge = false;
  int? _dernierEnfantId;
  _Filtre _filtre = _Filtre.tous;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _charge = true);
    try {
      final resultats = await Future.wait([
        if (user?.estParent == true)
          (() {
            final enfant = context.read<ChildProvider>().selectionne;
            if (enfant == null) return Future.value(<Announcement>[]);
            _dernierEnfantId = enfant.id;
            return _childrenService.getAnnonces(enfant.id);
          })()
        else
          _announcementService.getAnnonces(),
        _eventService.getEvenements(),
      ]);
      _annonces = resultats[0] as List<Announcement>;
      _evenements = resultats[1] as List<AcademicEvent>;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _archiverAnnonce(Announcement a) async {
    setState(() => _annonces.removeWhere((x) => x.id == a.id));
    try {
      await _announcementService.archiverAnnonce(a.id);
    } catch (_) {
      if (mounted) setState(() => _annonces.add(a));
    }
  }

  Future<void> _supprimerAnnonce(Announcement a) async {
    setState(() => _annonces.removeWhere((x) => x.id == a.id));
    try {
      await _announcementService.supprimerAnnonce(a.id);
    } catch (e) {
      if (mounted) {
        setState(() => _annonces.add(a));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estParent = auth.user?.estParent == true;
    final peutPublier = auth.user?.estAdmin == true || auth.user?.estEnseignant == true;
    final peutGererEvenements = auth.user?.estAdmin == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _charger,
            child: _charge
                ? ListView(padding: EdgeInsets.only(top: AppHeader.hauteur + 40), children: const [Center(child: CircularProgressIndicator())])
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, AppHeader.hauteur + 16, 16, 24),
                    children: [
                      if (estParent) ...[const ChildSelector(), const SizedBox(height: 14)],
                      _filtres(),
                      const SizedBox(height: 20),
                      if (_filtre != _Filtre.evenements) ..._sectionAnnonces(),
                      if (_filtre != _Filtre.annonces) ..._sectionEvenements(),
                      if (_annonces.isEmpty && _evenements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: EmptyState(
                            message: 'Rien pour l\'instant',
                            sousTitre: 'Les annonces et les événements à venir apparaîtront ici.',
                            icone: Icons.calendar_month_outlined,
                          ),
                        ),
                    ],
                  ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: AppHeader()),
        ],
      ),
      floatingActionButton: _boutonCreation(peutPublier, peutGererEvenements),
      bottomNavigationBar: const BottomNav(indexActuel: 4),
    );
  }

  Widget? _boutonCreation(bool peutPublier, bool peutGererEvenements) {
    if (!peutPublier && !peutGererEvenements) return null;
    if (peutPublier && peutGererEvenements) {
      return FloatingActionButton(
        backgroundColor: _Ag.primary,
        onPressed: () => showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: _Ag.primary),
                  title: const Text('Nouvelle annonce'),
                  onTap: () async {
                    Navigator.pop(context);
                    final publie = await context.push<bool>('/agenda/nouvelle-annonce');
                    if (publie == true) _charger();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined, color: _Ag.primary),
                  title: const Text('Nouvel événement'),
                  onTap: () async {
                    Navigator.pop(context);
                    final cree = await context.push<bool>('/agenda/nouvel-evenement');
                    if (cree == true) _charger();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.white),
      );
    }
    return FloatingActionButton(
      backgroundColor: _Ag.primary,
      tooltip: peutPublier ? 'Nouvelle annonce' : 'Nouvel événement',
      onPressed: () async {
        final resultat = await context.push<bool>(peutPublier ? '/agenda/nouvelle-annonce' : '/agenda/nouvel-evenement');
        if (resultat == true) _charger();
      },
      child: Icon(peutPublier ? Icons.campaign_outlined : Icons.event_outlined, color: AppColors.white),
    );
  }

  Widget _filtres() {
    final options = [
      (_Filtre.tous, 'Tous', Icons.auto_awesome_rounded),
      (_Filtre.annonces, 'Annonces', Icons.campaign_outlined),
      (_Filtre.evenements, 'Événements', Icons.event_outlined),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (valeur, label, icone) = options[i];
          final actif = _filtre == valeur;
          return GestureDetector(
            onTap: () => setState(() => _filtre = valeur),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: actif ? _Ag.primary : AppColors.white,
                borderRadius: BorderRadius.circular(30),
                border: actif ? null : Border.all(color: _Ag.outlineVariant),
                boxShadow: actif
                    ? [BoxShadow(color: _Ag.primary.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 16, color: actif ? AppColors.white : _Ag.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700, color: actif ? AppColors.white : _Ag.onSurfaceVariant)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _sectionAnnonces() {
    if (_annonces.isEmpty) return [];
    return [
      _titreSection('Annonces de la direction', _Ag.primary, '${_annonces.length} nouvelle${_annonces.length > 1 ? 's' : ''}'),
      const SizedBox(height: 12),
      ..._annonces.asMap().entries.map((entry) {
        final a = entry.value;
        return AnimatedEntry(
          index: entry.key,
          child: ArchivableTile(
            cle: a.id,
            onArchiver: () => _archiverAnnonce(a),
            onSupprimer: () => _supprimerAnnonce(a),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: a.category == 'urgence' ? _carteUrgente(a) : _carteAnnonce(a),
            ),
          ),
        );
      }),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _sectionEvenements() {
    if (_evenements.isEmpty) return [];
    return [
      _titreSection('Calendrier scolaire', _Ag.tertiary, null),
      const SizedBox(height: 12),
      ..._evenements.asMap().entries.map((entry) => AnimatedEntry(index: entry.key, child: _carteEvenement(entry.value))),
    ];
  }

  Widget _titreSection(String titre, Color couleur, String? badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: couleur, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: _Ag.onSurface)),
          ],
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _Ag.primaryContainer, borderRadius: BorderRadius.circular(30)),
            child: Text(badge, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _Ag.primaryDim)),
          ),
      ],
    );
  }

  Widget _carteUrgente(Announcement a) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [_Ag.primary, _Ag.primaryDim, Color(0xFF3730A3)]),
        boxShadow: [BoxShadow(color: _Ag.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF43F5E).withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                child: Text('URGENT',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 0.6)),
              ),
              Text(_depuis(a.publishedAt), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 12),
          Text(a.title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.white)),
          const SizedBox(height: 6),
          Text(a.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.white.withOpacity(0.92), height: 1.4)),
        ],
      ),
    );
  }

  Widget _carteAnnonce(Announcement a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Ag.outlineVariant),
        boxShadow: [BoxShadow(color: _Ag.onSurface.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: _Ag.primaryContainer, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.campaign_outlined, color: _Ag.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _Ag.onSurface)),
                const SizedBox(height: 4),
                Text(a.body, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _Ag.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _couleursEvenement = {
    'vacances':  _Ag.secondary,
    'examen':    _Ag.tertiary,
    'evenement': _Ag.primary,
    'reunion':   Color(0xFFF59E0B),
    'autre':     AppColors.muted,
  };

  Widget _carteEvenement(AcademicEvent e) {
    DateTime? date;
    try { date = DateTime.parse(e.startDate); } catch (_) {}
    final couleur = _couleursEvenement[e.category] ?? AppColors.muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Ag.outlineVariant),
        boxShadow: [BoxShadow(color: _Ag.onSurface.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [couleur, couleur.withOpacity(0.8)]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (date != null)
                  Text(DateFormat('E', 'fr_FR').format(date).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.white.withOpacity(0.85))),
                Text(date != null ? DateFormat('d').format(date) : '—',
                    style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.white)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: couleur.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
                  child: Text((categoriesEvenement[e.category] ?? e.category),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: couleur)),
                ),
                const SizedBox(height: 4),
                Text(e.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _Ag.onSurface)),
                if (e.description != null && e.description!.isNotEmpty)
                  Text(e.description!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _Ag.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _depuis(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return DateFormat('d MMM', 'fr_FR').format(date);
    } catch (_) {
      return '';
    }
  }
}
