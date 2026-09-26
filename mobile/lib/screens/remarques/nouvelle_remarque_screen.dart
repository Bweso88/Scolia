import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../services/remarques_service.dart';
import '../../services/student_service.dart';
import '../../widgets/success_toast.dart';

class NouvelleRemarqueScreen extends StatefulWidget {
  final int? eleveId;
  const NouvelleRemarqueScreen({super.key, this.eleveId});

  @override
  State<NouvelleRemarqueScreen> createState() => _NouvelleRemarqueScreenState();
}

class _NouvelleRemarqueScreenState extends State<NouvelleRemarqueScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _studentService = StudentService();
  final _remarquesService = RemarquesService();

  String _categorie = 'note_generale';
  bool _visibleParent = true;
  int? _eleveSelectionne;
  List<Student> _eleves = [];
  bool _charge = false;
  bool _envoi  = false;

  static const _categories = {
    'positive':      'Positif',
    'discipline':    'Discipline',
    'participation': 'Participation',
    'incident':      'Incident',
    'note_generale': 'Observation générale',
  };

  @override
  void initState() {
    super.initState();
    _eleveSelectionne = widget.eleveId;
    _chargerEleves();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEleves() async {
    setState(() => _charge = true);
    try {
      _eleves = await _studentService.getEleves();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eleveSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un élève'), backgroundColor: AppColors.orange),
      );
      return;
    }
    setState(() => _envoi = true);
    try {
      await _remarquesService.creerRemarque({
        'student_id':  _eleveSelectionne,
        'category':    _categorie,
        'title':       _titreCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'visible_to_parent': _visibleParent,
      });
      if (mounted) {
        showSuccessToast(context, 'Observation enregistrée.');
        context.pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle observation')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _eleveSelectionne,
                      decoration: const InputDecoration(labelText: 'Élève *'),
                      items: _eleves.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nomComplet))).toList(),
                      onChanged: (v) => setState(() => _eleveSelectionne = v),
                      validator: (v) => v == null ? 'Sélectionnez un élève' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categorie,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: _categories.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _categorie = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titreCtrl,
                      decoration: const InputDecoration(labelText: 'Titre *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionCtrl,
                      decoration: const InputDecoration(labelText: 'Description (facultatif)', alignLabelWithHint: true),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Visible par le parent'),
                      value: _visibleParent,
                      onChanged: (v) => setState(() => _visibleParent = v),
                      activeColor: AppColors.navy,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _envoi ? null : _envoyer,
                      child: _envoi
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
