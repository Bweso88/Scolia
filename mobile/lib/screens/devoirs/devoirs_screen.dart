import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/homework.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/children_service.dart';
import '../../services/homework_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';

enum _Filtre { aFaire, termine }

/// Cahier de texte / devoirs (docs/PRODUCT_ARCHITECTURE.md §4), repris du
/// mockup "Scholarly" fourni par l'utilisateur : bandeau de jours, filtre
/// à faire/terminé, et des cartes avec un bouton "Marquer fait" qui bascule
/// le statut réel du devoir pour cet enfant.
class DevoirsScreen extends StatefulWidget {
  const DevoirsScreen({super.key});

  @override
  State<DevoirsScreen> createState() => _DevoirsScreenState();
}

class _DevoirsScreenState extends State<DevoirsScreen> {
  final _childrenService = ChildrenService();
  final _homeworkService = HomeworkService();

  List<Homework> _devoirsParent = [];
  List<Homework> _devoirsPersonnel = [];
  bool _charge = false;
  int? _dernierEnfantId;
  late DateTime _jourSelectionne = DateTime.now();
  _Filtre _filtre = _Filtre.aFaire;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    if (user?.estParent == true) {
      await _chargerParent();
    } else {
      await _chargerPersonnel();
    }
  }

  Future<void> _chargerParent() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() => _charge = true);
    try {
      final devoirs = await _childrenService.getDevoirs(enfant.id, range: 'week');
      setState(() {
        _devoirsParent = devoirs;
        _dernierEnfantId = enfant.id;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _chargerPersonnel() async {
    setState(() => _charge = true);
    try {
      final classes = context.read<AuthProvider>().user?.classes ?? [];
      final devoirs = classes.isEmpty
          ? await _homeworkService.getDevoirs()
          : await _homeworkService.getDevoirs(schoolClassId: classes.first.id);
      setState(() => _devoirsPersonnel = devoirs);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _basculerStatut(Homework devoir) async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    final nouveauStatutOptimiste = devoir.estFait ? 'pending' : 'done';
    setState(() {
      _devoirsParent = _devoirsParent.map((d) => d.id == devoir.id ? d.copierAvecStatus(nouveauStatutOptimiste) : d).toList();
    });
    try {
      final statut = await _childrenService.basculerStatutDevoir(enfant.id, devoir.id);
      if (mounted) {
        setState(() {
          _devoirsParent = _devoirsParent.map((d) => d.id == devoir.id ? d.copierAvecStatus(statut) : d).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _devoirsParent = _devoirsParent.map((d) => d.id == devoir.id ? d.copierAvecStatus(devoir.status) : d).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de mettre à jour ce devoir.'), backgroundColor: AppColors.red));
      }
    }
  }

  List<DateTime> get _joursAffiches => List.generate(6, (i) {
        final j = DateTime.now().add(Duration(days: i));
        return DateTime(j.year, j.month, j.day);
      });

  bool _memeJour(String? dueDate, DateTime jour) {
    if (dueDate == null) return false;
    try {
      final d = DateTime.parse(dueDate);
      return d.year == jour.year && d.month == jour.month && d.day == jour.day;
    } catch (_) {
      return false;
    }
  }

  List<Homework> get _devoirsDuJourSelectionne =>
      _devoirsParent.where((d) => _memeJour(d.dueDate, _jourSelectionne)).toList();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final estParent = user?.estParent == true;

    final enfantCourant = context.watch<ChildProvider>().selectionne;
    if (estParent && enfantCourant != null && enfantCourant.id != _dernierEnfantId && !_charge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerParent());
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          estParent ? _corpsParent() : _corpsPersonnel(),
          const Positioned(top: 0, left: 0, right: 0, child: AppHeader()),
        ],
      ),
      floatingActionButton: user?.estEnseignant == true
          ? FloatingActionButton.extended(
              onPressed: () async {
                final publie = await context.push<bool>('/devoirs/publier');
                if (publie == true) _chargerPersonnel();
              },
              backgroundColor: AppColors.blue,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: Text('Publier', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          : null,
      bottomNavigationBar: const BottomNav(indexActuel: 1),
    );
  }

  Widget _corpsParent() {
    if (context.watch<ChildProvider>().enfants.isEmpty) {
      return ListView(
        padding: EdgeInsets.only(top: AppHeader.hauteur + 24),
        children: const [
          EmptyState(
            message: 'Aucun enfant lié',
            sousTitre: 'Contactez l\'école pour activer votre compte parent.',
            icone: Icons.child_care_outlined,
          ),
        ],
      );
    }

    final jourSelectionneHomeworks = _devoirsDuJourSelectionne;
    final aFaireDuJour = jourSelectionneHomeworks.where((d) => !d.estFait).toList();
    final termineDuJour = jourSelectionneHomeworks.where((d) => d.estFait).toList();
    final affiches = _filtre == _Filtre.aFaire ? aFaireDuJour : termineDuJour;

    return RefreshIndicator(
      onRefresh: _chargerParent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, AppHeader.hauteur + 16, 16, 100),
        children: [
          const ChildSelector(),
          const SizedBox(height: 18),
          Text('Cahier de texte', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(
            '${DateFormat('EEEE d MMMM', 'fr_FR').format(_jourSelectionne)} • ${aFaireDuJour.length} devoir${aFaireDuJour.length > 1 ? 's' : ''} à rendre',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _bandeauJours(),
          const SizedBox(height: 14),
          _filtreSegmente(aFaireDuJour.length, termineDuJour.length),
          const SizedBox(height: 16),
          if (_charge)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (affiches.isEmpty)
            _carteEncouragement()
          else
            ...affiches.map((d) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _carteDevoir(d))),
        ],
      ),
    );
  }

  Widget _bandeauJours() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _joursAffiches.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final jour = _joursAffiches[i];
          final actif = jour == _jourSelectionne;
          final nbPendantCeJour = _devoirsParent.where((d) => _memeJour(d.dueDate, jour)).toList();
          final aDuPending = nbPendantCeJour.any((d) => !d.estFait);
          return GestureDetector(
            onTap: () => setState(() => _jourSelectionne = jour),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: actif ? const LinearGradient(colors: [AppColors.blue, Color(0xFF4338CA)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                color: actif ? null : AppColors.white,
                boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(actif ? 0.18 : 0.04), blurRadius: actif ? 14 : 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('EEE', 'fr_FR').format(jour).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: actif ? AppColors.white.withOpacity(0.8) : AppColors.muted)),
                  Text('${jour.day}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: actif ? AppColors.white : AppColors.navy)),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nbPendantCeJour.isEmpty ? Colors.transparent : (aDuPending ? (actif ? AppColors.amber : AppColors.blue) : AppColors.green),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filtreSegmente(int nbAFaire, int nbTermine) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filtre = _Filtre.aFaire),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _filtre == _Filtre.aFaire ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: _filtre == _Filtre.aFaire ? [BoxShadow(color: AppColors.navy.withOpacity(0.06), blurRadius: 6)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('À faire', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('$nbAFaire', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filtre = _Filtre.termine),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _filtre == _Filtre.termine ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: _filtre == _Filtre.termine ? [BoxShadow(color: AppColors.navy.withOpacity(0.06), blurRadius: 6)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 15, color: AppColors.green),
                    const SizedBox(width: 5),
                    Text('Terminé', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.body)),
                    const SizedBox(width: 4),
                    Text('($nbTermine)', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteEncouragement() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_awesome, color: AppColors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            _filtre == _Filtre.aFaire ? 'C\'est tout pour cette journée !' : 'Rien de terminé pour l\'instant.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          Text(
            _filtre == _Filtre.aFaire ? 'Aucun devoir en attente pour ce jour.' : 'Les devoirs marqués faits apparaîtront ici.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.muted),
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

  ({String libelle, Color couleur})? _badgeUrgence(String? dueDate) {
    if (dueDate == null) return null;
    try {
      final due = DateTime.parse(dueDate);
      final today = DateTime.now();
      final diff = DateTime(due.year, due.month, due.day).difference(DateTime(today.year, today.month, today.day)).inDays;
      if (diff < 0) return (libelle: 'En retard', couleur: AppColors.red);
      if (diff == 0) return (libelle: 'Aujourd\'hui', couleur: AppColors.blue);
      if (diff == 1) return (libelle: 'Pour demain', couleur: const Color(0xFFE11D48));
      return null;
    } catch (_) {
      return null;
    }
  }

  Widget _carteDevoir(Homework devoir) {
    final couleur = _couleurMatiere(devoir.subjectName);
    final urgence = _badgeUrgence(devoir.dueDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    if (devoir.subjectName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: couleur.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 5, height: 5, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(devoir.subjectName!.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: couleur, letterSpacing: 0.3)),
                        ]),
                      ),
                    if (urgence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: urgence.couleur.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(urgence.libelle, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: urgence.couleur)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(devoir.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
          if (devoir.instructions != null && devoir.instructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(devoir.instructions!, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.body, height: 1.4)),
          ],
          if (devoir.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: devoir.attachments.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.description_outlined, size: 15, color: AppColors.red),
                  const SizedBox(width: 6),
                  Text(a.fileName, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.body)),
                  const SizedBox(width: 6),
                  Text(a.tailleAffichee, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted)),
                ]),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: AppColors.border.withOpacity(0.6), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (devoir.teacherName != null)
                Expanded(
                  child: Text(devoir.teacherName!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted), overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
              GestureDetector(
                onTap: () => _basculerStatut(devoir),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: devoir.estFait ? AppColors.green : AppColors.light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(devoir.estFait ? 'Fait' : 'Marquer fait',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: devoir.estFait ? AppColors.white : AppColors.body)),
                    const SizedBox(width: 6),
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: devoir.estFait ? AppColors.white.withOpacity(0.25) : AppColors.white, shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 14, color: devoir.estFait ? AppColors.white : AppColors.muted),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _corpsPersonnel() {
    return RefreshIndicator(
      onRefresh: _chargerPersonnel,
      child: _charge
          ? ListView(padding: EdgeInsets.only(top: AppHeader.hauteur + 32), children: const [Center(child: CircularProgressIndicator())])
          : _devoirsPersonnel.isEmpty
              ? ListView(
                  padding: EdgeInsets.only(top: AppHeader.hauteur + 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      message: 'Aucun devoir publié',
                      sousTitre: 'Publiez le premier devoir de votre classe.',
                      icone: Icons.assignment_outlined,
                      onAction: _chargerPersonnel,
                      libelleAction: 'Actualiser',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, AppHeader.hauteur + 16, 16, 100),
                  itemCount: _devoirsPersonnel.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CarteDevoirPersonnel(devoir: _devoirsPersonnel[i]),
                  ),
                ),
    );
  }
}

class _CarteDevoirPersonnel extends StatelessWidget {
  final Homework devoir;
  const _CarteDevoirPersonnel({required this.devoir});

  @override
  Widget build(BuildContext context) {
    DateTime? echeance;
    try { if (devoir.dueDate != null) echeance = DateTime.parse(devoir.dueDate!); } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.assignment_outlined, color: AppColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (devoir.subjectName != null)
                  Text(devoir.subjectName!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(devoir.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body)),
                if (devoir.instructions != null && devoir.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(devoir.instructions!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (echeance != null)
                      Text('À rendre le ${DateFormat('d MMM', 'fr_FR').format(echeance)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                    if (devoir.schoolClassName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(4)),
                        child: Text(devoir.schoolClassName!, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.muted)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Noter les élèves',
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.blue),
            onPressed: () => context.push('/notes/noter-devoir', extra: devoir),
          ),
        ],
      ),
    );
  }
}
