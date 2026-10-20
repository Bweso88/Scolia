import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/matiere.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/homework_service.dart';
import '../../services/reference_service.dart';
import '../../widgets/success_toast.dart';

/// Publication d'un devoir par un enseignant, en un minimum de champs
/// (docs/PRODUCT_ARCHITECTURE.md §4) : classe, matière, consigne, échéance.
class PublierDevoirScreen extends StatefulWidget {
  const PublierDevoirScreen({super.key});

  @override
  State<PublierDevoirScreen> createState() => _PublierDevoirScreenState();
}

class _PublierDevoirScreenState extends State<PublierDevoirScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _consignesCtrl = TextEditingController();
  final _homeworkService = HomeworkService();
  final _referenceService = ReferenceService();

  List<Matiere> _matieres = [];
  List<UserClasse> _classes = [];
  int? _classeSelectionnee;
  int? _matiereSelectionnee;
  DateTime _echeance = DateTime.now().add(const Duration(days: 1));
  bool _charge = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _classes = context.read<AuthProvider>().user?.classes ?? [];
    _classeSelectionnee = _classes.isNotEmpty ? _classes.first.id : null;
    _chargerMatieres();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _consignesCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerMatieres() async {
    setState(() => _charge = true);
    try {
      _matieres = await _referenceService.getMatieres();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classeSelectionnee == null || _matiereSelectionnee == null) {
      _snack('Sélectionnez une classe et une matière.', AppColors.orange);
      return;
    }

    setState(() => _envoi = true);
    try {
      await _homeworkService.publierDevoir({
        'school_class_id': _classeSelectionnee,
        'subject_id': _matiereSelectionnee,
        'title': _titreCtrl.text.trim(),
        'instructions': _consignesCtrl.text.trim().isEmpty ? null : _consignesCtrl.text.trim(),
        'due_date': DateFormat('yyyy-MM-dd').format(_echeance),
      });
      if (mounted) {
        showSuccessToast(context, 'Devoir publié.');
        context.pop(true);
      }
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.red);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _echeance,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _echeance = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publier un devoir')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_classes.length > 1)
                      DropdownButtonFormField<int>(
                        value: _classeSelectionnee,
                        decoration: const InputDecoration(labelText: 'Classe *'),
                        items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (v) => setState(() => _classeSelectionnee = v),
                      )
                    else if (_classes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('Aucune classe ne vous est assignée : contactez l\'administration.',
                            style: TextStyle(color: AppColors.red)),
                      ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _matiereSelectionnee,
                      decoration: const InputDecoration(labelText: 'Matière *'),
                      items: _matieres.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nom))).toList(),
                      onChanged: (v) => setState(() => _matiereSelectionnee = v),
                      validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titreCtrl,
                      decoration: const InputDecoration(labelText: 'Titre *', hintText: 'Ex : Exercices 1 à 5 page 42'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _consignesCtrl,
                      decoration: const InputDecoration(labelText: 'Consignes (facultatif)', alignLabelWithHint: true),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('À rendre le', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.muted)),
                      subtitle: Text(DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_echeance),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.navy)),
                      trailing: const Icon(Icons.calendar_today_outlined, color: AppColors.navy),
                      onTap: _choisirDate,
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _envoi ? null : _publier,
                      child: _envoi
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Publier le devoir'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
