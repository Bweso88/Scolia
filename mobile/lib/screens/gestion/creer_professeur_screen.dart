import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/matiere.dart';
import '../../models/school_class_admin.dart';
import '../../models/teacher_admin.dart';
import '../../services/gestion_service.dart';
import '../../services/reference_service.dart';
import '../../widgets/success_toast.dart';

/// Création ou modification d'un professeur, avec ses affectations
/// classe/matière (docs/PRODUCT_ARCHITECTURE.md §15).
class CreerProfesseurScreen extends StatefulWidget {
  final TeacherAdmin? professeur;
  const CreerProfesseurScreen({super.key, this.professeur});

  @override
  State<CreerProfesseurScreen> createState() => _CreerProfesseurScreenState();
}

class _CreerProfesseurScreenState extends State<CreerProfesseurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _service = GestionService();
  final _referenceService = ReferenceService();

  List<SchoolClassAdmin> _classes = [];
  List<Matiere> _matieres = [];
  final List<({int? classeId, int? matiereId})> _affectations = [];
  bool _charge = false;
  bool _envoi = false;

  bool get _modification => widget.professeur != null;

  @override
  void initState() {
    super.initState();
    _matriculeCtrl.text = widget.professeur?.employeeNumber ?? '';
    if (widget.professeur != null) {
      _nomCtrl.text = widget.professeur!.name ?? '';
      _emailCtrl.text = widget.professeur!.email ?? '';
      for (final a in widget.professeur!.assignments) {
        _affectations.add((classeId: a.schoolClassId, matiereId: a.subjectId));
      }
    }
    _chargerReferences();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    _matriculeCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerReferences() async {
    setState(() => _charge = true);
    try {
      final resultats = await Future.wait([_service.getClasses(), _referenceService.getMatieres()]);
      _classes = resultats[0] as List<SchoolClassAdmin>;
      _matieres = resultats[1] as List<Matiere>;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final assignments = _affectations
        .where((a) => a.classeId != null && a.matiereId != null)
        .map((a) => {'school_class_id': a.classeId, 'subject_id': a.matiereId})
        .toList();
    try {
      if (_modification) {
        await _service.modifierProfesseur(widget.professeur!.id, {
          'employee_number': _matriculeCtrl.text.trim().isEmpty ? null : _matriculeCtrl.text.trim(),
          'assignments': assignments,
        });
      } else {
        await _service.creerProfesseur({
          'name': _nomCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _motDePasseCtrl.text,
          'employee_number': _matriculeCtrl.text.trim().isEmpty ? null : _matriculeCtrl.text.trim(),
          'assignments': assignments,
        });
      }
      if (mounted) {
        showSuccessToast(context, _modification ? 'Professeur modifié.' : 'Professeur créé.');
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
      appBar: AppBar(title: Text(_modification ? 'Modifier le professeur' : 'Nouveau professeur')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_modification) ...[
                      TextFormField(
                        controller: _nomCtrl,
                        decoration: const InputDecoration(labelText: 'Nom complet *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email *'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.trim().isEmpty ? 'L\'email est requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _motDePasseCtrl,
                        decoration: const InputDecoration(labelText: 'Mot de passe *'),
                        obscureText: true,
                        validator: (v) => v == null || v.length < 8 ? 'Au moins 8 caractères' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _matriculeCtrl,
                      decoration: const InputDecoration(labelText: 'Matricule (facultatif)'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Classes et matières enseignées', style: Theme.of(context).textTheme.titleSmall),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.navy),
                          onPressed: () => setState(() => _affectations.add((classeId: null, matiereId: null))),
                        ),
                      ],
                    ),
                    ..._affectations.asMap().entries.map((entry) {
                      final i = entry.key;
                      final a = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: a.classeId,
                                decoration: const InputDecoration(labelText: 'Classe'),
                                items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                onChanged: (v) => setState(() => _affectations[i] = (classeId: v, matiereId: a.matiereId)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: a.matiereId,
                                decoration: const InputDecoration(labelText: 'Matière'),
                                items: _matieres.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nom))).toList(),
                                onChanged: (v) => setState(() => _affectations[i] = (classeId: a.classeId, matiereId: v)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.red),
                              onPressed: () => setState(() => _affectations.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _envoi ? null : _enregistrer,
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
