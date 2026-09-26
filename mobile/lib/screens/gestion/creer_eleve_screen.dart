import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/school_class_admin.dart';
import '../../models/student.dart';
import '../../models/student_guardian.dart';
import '../../services/gestion_service.dart';
import '../../services/student_service.dart';

/// Création ou modification d'un élève, avec ses parents/tuteurs
/// (docs/PRODUCT_ARCHITECTURE.md §15) — la liaison aux parents n'est
/// possible qu'en modification (il faut d'abord un identifiant d'élève).
class CreerEleveScreen extends StatefulWidget {
  final Student? eleve;
  const CreerEleveScreen({super.key, this.eleve});

  @override
  State<CreerEleveScreen> createState() => _CreerEleveScreenState();
}

class _CreerEleveScreenState extends State<CreerEleveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _matriculeCtrl = TextEditingController();
  final _studentService = StudentService();
  final _gestionService = GestionService();

  List<SchoolClassAdmin> _classes = [];
  List<StudentGuardianAdmin> _parents = [];
  int? _classeId;
  String? _genre;
  DateTime? _naissance;
  bool _charge = false;
  bool _envoi = false;

  bool get _modification => widget.eleve != null;

  @override
  void initState() {
    super.initState();
    _prenomCtrl.text = widget.eleve?.firstName ?? '';
    _nomCtrl.text = widget.eleve?.lastName ?? '';
    _matriculeCtrl.text = widget.eleve?.enrollmentNumber ?? '';
    _classeId = widget.eleve?.schoolClass?.id;
    _charger();
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _matriculeCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _classes = await _gestionService.getClasses();
      if (_modification) {
        _parents = await _gestionService.getParents(widget.eleve!.id);
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
      'school_class_id': _classeId,
      'first_name': _prenomCtrl.text.trim(),
      'last_name': _nomCtrl.text.trim(),
      'birth_date': _naissance != null ? DateFormat('yyyy-MM-dd').format(_naissance!) : null,
      'gender': _genre,
      'enrollment_number': _matriculeCtrl.text.trim().isEmpty ? null : _matriculeCtrl.text.trim(),
    };
    try {
      if (_modification) {
        await _studentService.modifierEleve(widget.eleve!.id, corps);
      } else {
        await _studentService.creerEleve(corps);
      }
      if (mounted) context.pop(true);
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _choisirDateNaissance() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _naissance ?? DateTime(DateTime.now().year - 8),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _naissance = date);
  }

  Future<void> _ajouterParent() async {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mdpCtrl = TextEditingController();
    String lien = 'mère';

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ajouter un parent'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom complet')),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                TextField(controller: mdpCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
                DropdownButtonFormField<String>(
                  initialValue: lien,
                  decoration: const InputDecoration(labelText: 'Lien de parenté'),
                  items: const [
                    DropdownMenuItem(value: 'mère', child: Text('Mère')),
                    DropdownMenuItem(value: 'père', child: Text('Père')),
                    DropdownMenuItem(value: 'tuteur', child: Text('Tuteur/tutrice')),
                    DropdownMenuItem(value: 'autre', child: Text('Autre')),
                  ],
                  onChanged: (v) => setDialogState(() => lien = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
          ],
        ),
      ),
    );

    if (confirme != true || nomCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

    try {
      await _gestionService.lierParent(widget.eleve!.id, {
        'name': nomCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'password': mdpCtrl.text,
        'relationship_type': lien,
      });
      _charger();
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _retirerParent(StudentGuardianAdmin p) async {
    try {
      await _gestionService.delierParent(widget.eleve!.id, p.id);
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
      appBar: AppBar(title: Text(_modification ? 'Modifier l\'élève' : 'Nouvel élève')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _classeId,
                      decoration: const InputDecoration(labelText: 'Classe *'),
                      items: _classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _classeId = v),
                      validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _prenomCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le prénom est requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nomCtrl,
                      decoration: const InputDecoration(labelText: 'Nom *'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date de naissance'),
                      subtitle: Text(_naissance != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(_naissance!) : 'Non renseignée'),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: _choisirDateNaissance,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _genre,
                      decoration: const InputDecoration(labelText: 'Genre (facultatif)'),
                      items: const [
                        DropdownMenuItem(value: 'm', child: Text('Masculin')),
                        DropdownMenuItem(value: 'f', child: Text('Féminin')),
                      ],
                      onChanged: (v) => setState(() => _genre = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _matriculeCtrl,
                      decoration: const InputDecoration(labelText: 'Numéro d\'inscription (facultatif)'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _envoi ? null : _enregistrer,
                      child: _envoi
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Enregistrer'),
                    ),

                    if (_modification) ...[
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Parents / tuteurs', style: Theme.of(context).textTheme.titleSmall),
                          IconButton(
                            icon: const Icon(Icons.person_add_outlined, color: AppColors.navy),
                            onPressed: _ajouterParent,
                          ),
                        ],
                      ),
                      if (_parents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Aucun parent lié pour l\'instant.', style: TextStyle(color: AppColors.muted)),
                        )
                      else
                        ..._parents.map((p) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(p.name ?? '—'),
                              subtitle: Text('${p.relationshipType}${p.isPrimaryContact ? ' · Contact principal' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.red),
                                onPressed: () => _retirerParent(p),
                              ),
                            )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
