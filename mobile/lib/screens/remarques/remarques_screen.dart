import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../config/theme.dart';
import '../../models/remarque.dart';
import '../../services/children_service.dart';
import '../../services/remarques_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/archivable_tile.dart';
import '../../widgets/empty_state.dart';

/// Palette propre à cet écran, reprise du mockup fourni ("Suivi &
/// Remarques") — même famille de bleus que l'écran de connexion/Agenda.
class _Su {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF16A34A);
  static const tertiary = Color(0xFF8B5CF6);
  static const warning = Color(0xFFF59E0B);
  static const onSurface = Color(0xFF0F172A);
  static const onSurfaceVariant = Color(0xFF64748B);
  static const outline = Color(0xFFE2E8F0);
}

/// Comportement — "Suivi" (docs/PRODUCT_ARCHITECTURE.md §5) : historique des
/// observations, résumé d'humeur de la semaine et accusé de lecture par le
/// parent ; publication réservée au personnel.
class RemarquesScreen extends StatefulWidget {
  const RemarquesScreen({super.key});

  @override
  State<RemarquesScreen> createState() => _RemarquesScreenState();
}

class _RemarquesScreenState extends State<RemarquesScreen> {
  final _childrenService = ChildrenService();
  final _remarquesService = RemarquesService();

  List<Remarque> _remarques = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _archiver(Remarque r) async {
    setState(() => _remarques.removeWhere((x) => x.id == r.id));
    try {
      await _remarquesService.archiverRemarque(r.id);
    } catch (_) {
      if (mounted) setState(() => _remarques.add(r));
    }
  }

  Future<void> _supprimer(Remarque r) async {
    setState(() => _remarques.removeWhere((x) => x.id == r.id));
    try {
      await _remarquesService.supprimerRemarque(r.id);
    } catch (e) {
      if (mounted) {
        setState(() => _remarques.add(r));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  Future<void> _confirmerLecture(Remarque r) async {
    try {
      final maj = await _remarquesService.acquitterRemarque(r.id);
      if (!mounted) return;
      setState(() {
        final i = _remarques.indexWhere((x) => x.id == r.id);
        if (i != -1) _remarques[i] = maj;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _charge = true);
    try {
      if (user?.estParent == true) {
        final enfant = context.read<ChildProvider>().selectionne;
        if (enfant == null) return;
        _remarques = await _childrenService.getComportement(enfant.id);
        _dernierEnfantId = enfant.id;
      } else {
        _remarques = await _remarquesService.getRemarques();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estParent = auth.user?.estParent == true;
    final peutEcrire = auth.user?.faitPartieDuPersonnel == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    return Scaffold(
      backgroundColor: AppColors.light,
      appBar: AppBar(
        title: const Text('Suivi'),
        actions: [
          if (peutEcrire)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () async {
                final cree = await context.push<bool>('/remarques/nouvelle');
                if (cree == true) _charger();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (estParent) ...[
            const SizedBox(height: 12),
            const ChildSelector(),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: _charge
                  ? const Center(child: CircularProgressIndicator())
                  : _remarques.isEmpty
                      ? EmptyState(
                          message: 'Aucune observation',
                          sousTitre: 'Les observations de comportement apparaîtront ici.',
                          icone: Icons.comment_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            _semaineHumeur(),
                            const SizedBox(height: 22),
                            Text('Notes de l\'équipe pédagogique',
                                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _Su.onSurface)),
                            const SizedBox(height: 12),
                            ..._remarques.asMap().entries.map((entry) {
                              final r = entry.value;
                              return AnimatedEntry(
                                index: entry.key,
                                child: ArchivableTile(
                                  cle: r.id,
                                  onArchiver: () => _archiver(r),
                                  onSupprimer: () => _supprimer(r),
                                  child: _carteRemarque(r, estParent),
                                ),
                              );
                            }),
                            const SizedBox(height: 22),
                            _statistiques(),
                          ],
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 2),
    );
  }

  static const _categorieStyle = {
    'positive':      (couleur: _Su.secondary, icone: Icons.sentiment_very_satisfied_rounded, libelle: 'Positif'),
    'participation': (couleur: _Su.secondary, icone: Icons.sentiment_satisfied_rounded, libelle: 'Participation'),
    'discipline':    (couleur: _Su.tertiary, icone: Icons.edit_note_rounded, libelle: 'Discipline'),
    'incident':      (couleur: AppColors.red, icone: Icons.report_outlined, libelle: 'Incident'),
    'note_generale': (couleur: _Su.primary, icone: Icons.comment_outlined, libelle: 'Observation'),
  };

  /// Résumé du jour le plus préoccupant parmi les observations (incident >
  /// discipline > note générale > participation > positif), sur les 5
  /// derniers jours ouvrés se terminant aujourd'hui.
  Widget _semaineHumeur() {
    const ordreGravite = ['incident', 'discipline', 'note_generale', 'participation', 'positive'];
    final aujourdhui = DateTime.now();
    // Le lundi de la semaine en cours.
    final lundi = aujourdhui.subtract(Duration(days: aujourdhui.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Su.outline),
        boxShadow: [BoxShadow(color: _Su.onSurface.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: List.generate(5, (i) {
          final jour = lundi.add(Duration(days: i));
          final estAujourdhui = _memeJour(jour, aujourdhui);
          final estFutur = jour.isAfter(aujourdhui) && !estAujourdhui;

          final duJour = _remarques.where((r) {
            if (r.occurredAt == null) return false;
            try { return _memeJour(DateTime.parse(r.occurredAt!), jour); } catch (_) { return false; }
          }).toList();

          String? pire;
          for (final cat in ordreGravite) {
            if (duJour.any((r) => r.category == cat)) { pire = cat; break; }
          }

          late final Color couleur;
          late final IconData icone;
          late final String etiquette;
          late final Color fond;

          if (pire != null) {
            final style = _categorieStyle[pire]!;
            couleur = style.couleur;
            icone = style.icone;
            etiquette = style.libelle == 'Positif' ? 'TB' : (style.libelle == 'Participation' ? 'Bien' : style.libelle);
            fond = couleur.withOpacity(0.10);
          } else if (estAujourdhui) {
            couleur = _Su.primary;
            icone = Icons.star_rounded;
            etiquette = "Aujourd'hui";
            fond = _Su.primary.withOpacity(0.10);
          } else if (estFutur) {
            couleur = AppColors.muted;
            icone = Icons.hourglass_empty_rounded;
            etiquette = 'À venir';
            fond = AppColors.light;
          } else {
            couleur = AppColors.muted;
            icone = Icons.remove_rounded;
            etiquette = '—';
            fond = AppColors.light;
          }

          return Expanded(
            child: Column(
              children: [
                Text(DateFormat('E d', 'fr_FR').format(jour),
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: _Su.onSurfaceVariant)),
                const SizedBox(height: 6),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: fond,
                    borderRadius: BorderRadius.circular(11),
                    border: estAujourdhui ? Border.all(color: couleur, width: 1.6) : null,
                  ),
                  child: Icon(icone, size: 17, color: couleur),
                ),
                const SizedBox(height: 4),
                Text(etiquette,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w700, color: couleur),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }),
      ),
    );
  }

  bool _memeJour(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _carteRemarque(Remarque r, bool estParent) {
    final style = _categorieStyle[r.category] ?? _categorieStyle['note_generale']!;

    DateTime? date;
    try { if (r.occurredAt != null) date = DateTime.parse(r.occurredAt!); } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: style.couleur, width: 5),
          top: BorderSide(color: _Su.outline),
          right: BorderSide(color: _Su.outline),
          bottom: BorderSide(color: _Su.outline),
        ),
        boxShadow: [BoxShadow(color: _Su.onSurface.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: style.couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(style.icone, color: style.couleur, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (r.authorName != null)
                          Flexible(child: Text(r.authorName!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: _Su.onSurface), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: style.couleur.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(style.libelle, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: style.couleur)),
                        ),
                      ],
                    ),
                    if (date != null)
                      Text(DateFormat('d MMMM yyyy', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _Su.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(12)),
              child: Text('« ${r.description!} »', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body, height: 1.4)),
            ),
          ],
          if (estParent && r.visibleToParent) ...[
            const SizedBox(height: 12),
            if (r.estAcquittee)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _Su.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _Su.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.acknowledgedByName != null ? 'Lu par ${r.acknowledgedByName}' : 'Lecture confirmée',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _Su.secondary),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmerLecture(r),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Confirmer la lecture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Su.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statistiques() {
    final positives = _remarques.where((r) => r.category == 'positive').length;
    final vigilance = _remarques.where((r) => r.category == 'discipline' || r.category == 'incident').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques & bilan', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _Su.onSurface)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _carteStat(icone: Icons.celebration_rounded, valeur: positives, libelle: 'Bravo !', sousTitre: 'Remarques positives', couleur: _Su.secondary)),
            const SizedBox(width: 12),
            Expanded(child: _carteStat(icone: Icons.lightbulb_outline_rounded, valeur: vigilance, libelle: 'Vigilance', sousTitre: 'À surveiller', couleur: _Su.tertiary)),
          ],
        ),
      ],
    );
  }

  Widget _carteStat({required IconData icone, required int valeur, required String libelle, required String sousTitre, required Color couleur}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: couleur.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, size: 17, color: couleur),
          ),
          const SizedBox(height: 10),
          Text('$valeur', style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w800, color: couleur)),
          Text(libelle, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _Su.onSurface, letterSpacing: 0.4)),
          Text(sousTitre, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _Su.onSurfaceVariant)),
        ],
      ),
    );
  }
}
