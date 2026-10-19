import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/annee_scolaire.dart';
import '../../models/periode.dart';
import '../../services/notes_service.dart';
import '../../services/reference_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/success_toast.dart';

/// Calendrier des compositions / périodes de notation (ex. "1er trimestre",
/// "Compositions de janvier") : tant que la direction n'en a défini aucune,
/// les enseignants ne peuvent saisir aucune note nulle part dans l'app, le
/// champ étant obligatoire sur chaque note (voir le message bloquant affiché
/// sur les écrans Notes/Noter le devoir).
class PeriodesNotationScreen extends StatefulWidget {
  const PeriodesNotationScreen({super.key});

  @override
  State<PeriodesNotationScreen> createState() => _PeriodesNotationScreenState();
}

class _PeriodesNotationScreenState extends State<PeriodesNotationScreen> {
  final _notesService = NotesService();
  final _referenceService = ReferenceService();

  List<Periode> _periodes = [];
  List<AnneeScolaire> _annees = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      final resultats = await Future.wait([
        _notesService.getPeriodes(),
        _referenceService.getAnneesScolaires(),
      ]);
      setState(() {
        _periodes = resultats[0] as List<Periode>;
        _annees = resultats[1] as List<AnneeScolaire>;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _ajouter() async {
    if (_annees.isEmpty) {
      _snack('Aucune année scolaire n\'est configurée pour cette école. Contactez le support.', AppColors.orange);
      return;
    }
    final labelCtrl = TextEditingController();
    int anneeSelectionnee = (_annees.firstWhere((a) => a.estEnCours, orElse: () => _annees.first)).id;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle période de notation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Intitulé (ex. "1er trimestre")'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: anneeSelectionnee,
                decoration: const InputDecoration(labelText: 'Année scolaire'),
                items: _annees.map((a) => DropdownMenuItem(value: a.id, child: Text(a.label))).toList(),
                onChanged: (v) => setDialogState(() => anneeSelectionnee = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Créer')),
          ],
        ),
      ),
    );
    if (confirme != true || labelCtrl.text.trim().isEmpty) return;

    try {
      await _notesService.creerPeriode(label: labelCtrl.text.trim(), anneeScolaireId: anneeSelectionnee);
      if (mounted) showSuccessToast(context, 'Période de notation créée.');
      _charger();
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.red);
    }
  }

  Future<void> _supprimer(Periode p) async {
    try {
      await _notesService.supprimerPeriode(p.id);
      _charger();
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.red);
    }
  }

  void _snack(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Périodes de notation')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _periodes.isEmpty
                ? EmptyState(
                    message: 'Aucune période de notation',
                    sousTitre: 'Tant qu\'aucune période n\'est créée, les enseignants ne peuvent saisir aucune note. Créez la première (ex. "1er trimestre").',
                    icone: Icons.calendar_month_outlined,
                    onAction: _ajouter,
                    libelleAction: 'Créer une période',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _periodes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _periodes[i];
                      return ListTile(
                        leading: const Icon(Icons.calendar_month_outlined, color: AppColors.blue),
                        title: Text(p.nom, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.red),
                          onPressed: () => _supprimer(p),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouter,
        backgroundColor: AppColors.blue,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
