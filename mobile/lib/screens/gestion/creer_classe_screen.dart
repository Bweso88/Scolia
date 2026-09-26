import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/school_class_admin.dart';
import '../../models/school_year_ref.dart';
import '../../models/teacher_admin.dart';
import '../../services/gestion_service.dart';

/// Création ou modification d'une classe (docs/PRODUCT_ARCHITECTURE.md §15).
class CreerClasseScreen extends StatefulWidget {
  final SchoolClassAdmin? classe;
  const CreerClasseScreen({super.key, this.classe});

  @override
  State<CreerClasseScreen> createState() => _CreerClasseScreenState();
}

class _CreerClasseScreenState extends State<CreerClasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _service = GestionService();

  List<SchoolYearRef> _annees = [];
  List<TeacherAdmin> _profs = [];
  int? _anneeId;
  int? _profPrincipalId;
  bool _charge = false;
  bool _envoi = false;

  bool get _modification => widget.classe != null;

  @override
  void initState() {
    super.initState();
    _nomCtrl.text = widget.classe?.name ?? '';
    _niveauCtrl.text = widget.classe?.level ?? '';
    _anneeId = widget.classe?.schoolYearId;
    _profPrincipalId = widget.classe?.homeroomTeacherId;
    _chargerReferences();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _niveauCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerReferences() async {
    setState(() => _charge = true);
    try {
      final resultats = await Future.wait([_service.getAnneesScolaires(), _service.getProfesseurs()]);
      _annees = resultats[0] as List<SchoolYearRef>;
      _profs = resultats[1] as List<TeacherAdmin>;
      if (_anneeId == null && _annees.isNotEmpty) {
        final courante = _annees.where((a) => a.isCurrent);
        _anneeId = courante.isNotEmpty ? courante.first.id : _annees.first.id;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    final corps = {
      'name': _nomCtrl.text.trim(),
      'level': _niveauCtrl.text.trim().isEmpty ? null : _niveauCtrl.text.trim(),
      'school_year_id': _anneeId,
      'homeroom_teacher_id': _profPrincipalId,
    };
    try {
      if (_modification) {
        await _service.modifierClasse(widget.classe!.id, corps);
      } else {
        await _service.creerClasse(corps);
      }
      if (mounted) context.pop(true);
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
      appBar: AppBar(title: Text(_modification ? 'Modifier la classe' : 'Nouvelle classe')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom de la classe *', hintText: 'Ex : CM2'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _niveauCtrl,
                      decoration: const InputDecoration(labelText: 'Niveau (facultatif)', hintText: 'Ex : Primaire'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _anneeId,
                      decoration: const InputDecoration(labelText: 'Année scolaire *'),
                      items: _annees.map((a) => DropdownMenuItem(value: a.id, child: Text(a.label))).toList(),
                      onChanged: (v) => setState(() => _anneeId = v),
                      validator: (v) => v == null ? 'Sélectionnez une année scolaire' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      initialValue: _profPrincipalId,
                      decoration: const InputDecoration(labelText: 'Professeur principal (facultatif)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Aucun')),
                        ..._profs.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name ?? '—'))),
                      ],
                      onChanged: (v) => setState(() => _profPrincipalId = v),
                    ),
                    const SizedBox(height: 24),
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
