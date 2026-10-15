import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';
import '../../models/note.dart';
import '../../services/children_service.dart';

/// Notes (docs/PRODUCT_ARCHITECTURE.md §10) : module activable/désactivable
/// par école — l'API répond 403 avec un message explicite si désactivé.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _childrenService = ChildrenService();

  List<Note> _notes = [];
  bool _charge = false;
  String? _erreur;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() { _charge = true; _erreur = null; });
    try {
      _notes = await _childrenService.getNotes(enfant.id);
      _dernierEnfantId = enfant.id;
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Map<String, List<Note>> get _notesParPeriode {
    final groupes = <String, List<Note>>{};
    for (final n in _notes) {
      groupes.putIfAbsent(n.periodeNom ?? 'Sans période', () => []).add(n);
    }
    return groupes;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: user?.estParent == true ? _vueParent() : _vueEnseignant(context),
      bottomNavigationBar: const BottomNav(indexActuel: 4),
    );
  }

  Widget _vueParent() {
    if (context.watch<ChildProvider>().enfants.isEmpty) {
      return const EmptyState(
        message: 'Aucun enfant lié',
        sousTitre: 'Contactez l\'école pour activer votre compte parent.',
        icone: Icons.bar_chart_outlined,
      );
    }

    final enfant = context.watch<ChildProvider>().selectionne;
    if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const ChildSelector(),
          const SizedBox(height: 8),
          Expanded(
            child: _charge
                ? const Center(child: CircularProgressIndicator())
                : _erreur != null
                    ? EmptyState(message: 'Notes indisponibles', sousTitre: _erreur, icone: Icons.lock_outline, onAction: _charger, libelleAction: 'Réessayer')
                    : _notes.isEmpty
                        ? const EmptyState(
                            message: 'Aucune note disponible',
                            sousTitre: 'Les notes apparaîtront ici une fois saisies par l\'enseignant.',
                            icone: Icons.bar_chart_outlined,
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: _notesParPeriode.entries
                                .map((entree) => _CartePeriode(periode: entree.key, notes: entree.value))
                                .toList(),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _vueEnseignant(BuildContext context) {
    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined, color: AppColors.navy),
                title: Text('Voir ma classe',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                subtitle: Text('Liste des élèves',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                onTap: () => context.go('/teacher/ma-classe'),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => context.push('/notes/saisir'),
            backgroundColor: AppColors.navy,
            icon: const Icon(Icons.add, color: AppColors.white),
            label: Text('Saisir une note',
                style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _CartePeriode extends StatelessWidget {
  final String periode;
  final List<Note> notes;
  const _CartePeriode({required this.periode, required this.notes});

  @override
  Widget build(BuildContext context) {
    final moyenne = moyennePonderee(notes);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(periode, style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                if (moyenne != null)
                  Text('${moyenne.toStringAsFixed(2)}/20',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          ...notes.map((n) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.matiereNom ?? '—', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.body)),
                          Text('Coeff. ${n.coefficient.toStringAsFixed(1)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                          if (n.commentaire != null && n.commentaire!.isNotEmpty)
                            Text(n.commentaire!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: n.couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(n.affichage, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: n.couleur, fontSize: 14)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
