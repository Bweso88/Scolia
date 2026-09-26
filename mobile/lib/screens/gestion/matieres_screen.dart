import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/matiere.dart';
import '../../services/reference_service.dart';
import '../../widgets/empty_state.dart';

class MatieresScreen extends StatefulWidget {
  const MatieresScreen({super.key});

  @override
  State<MatieresScreen> createState() => _MatieresScreenState();
}

class _MatieresScreenState extends State<MatieresScreen> {
  final _service = ReferenceService();
  List<Matiere> _matieres = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _matieres = await _service.getMatieres();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _ajouter() async {
    final controleur = TextEditingController();
    final nom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle matière'),
        content: TextField(controller: controleur, decoration: const InputDecoration(labelText: 'Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controleur.text.trim()), child: const Text('Ajouter')),
        ],
      ),
    );
    if (nom == null || nom.isEmpty) return;
    try {
      await _service.creerMatiere(nom);
      _charger();
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _supprimer(Matiere m) async {
    try {
      await _service.supprimerMatiere(m.id);
      _charger();
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matières')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _matieres.isEmpty
                ? EmptyState(
                    message: 'Aucune matière',
                    sousTitre: 'Ajoutez la première matière de l\'école.',
                    icone: Icons.menu_book_outlined,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _matieres.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = _matieres[i];
                      return ListTile(
                        title: Text(m.nom, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.red),
                          onPressed: () => _supprimer(m),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _ajouter, backgroundColor: AppColors.navy, child: const Icon(Icons.add, color: AppColors.white)),
    );
  }
}
