import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/school_class_admin.dart';
import '../../models/student.dart';
import '../../models/student_guardian.dart';
import '../../services/gestion_service.dart';
import '../../services/student_service.dart';
import '../../widgets/success_toast.dart';

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
      if (mounted) {
        showSuccessToast(context, _modification ? 'Élève modifié.' : 'Élève créé.');
        context.pop(true);
      }
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
    final corps = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AjouterParentDialog(gestionService: _gestionService),
    );

    if (corps == null) return;

    try {
      await _gestionService.lierParent(widget.eleve!.id, corps);
      if (mounted) showSuccessToast(context, 'Parent lié à l\'élève.');
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

/// Dialogue "Ajouter un parent" : soit rattacher un parent déjà inscrit
/// dans l'école (fratrie — recherche par nom/email), soit en créer un
/// nouveau. Retourne le corps à envoyer à POST .../guardians, ou null si
/// annulé.
class _AjouterParentDialog extends StatefulWidget {
  final GestionService gestionService;
  const _AjouterParentDialog({required this.gestionService});

  @override
  State<_AjouterParentDialog> createState() => _AjouterParentDialogState();
}

class _AjouterParentDialogState extends State<_AjouterParentDialog> {
  bool _parentExistant = true;
  String _lien = 'mère';

  // Onglet "parent existant"
  final _rechercheCtrl = TextEditingController();
  Timer? _debounce;
  List<ParentSummary> _resultats = [];
  ParentSummary? _selectionne;
  bool _recherche = false;

  // Onglet "nouveau parent"
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lancerRecherche('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  void _surChangementRecherche(String valeur) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _lancerRecherche(valeur));
  }

  Future<void> _lancerRecherche(String valeur) async {
    setState(() => _recherche = true);
    try {
      final resultats = await widget.gestionService.rechercherParents(valeur.trim());
      if (mounted) setState(() => _resultats = resultats);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _recherche = false);
    }
  }

  void _valider() {
    final Map<String, dynamic> corps;
    if (_parentExistant) {
      if (_selectionne == null) return;
      corps = {'user_id': _selectionne!.id, 'relationship_type': _lien};
    } else {
      if (_nomCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _mdpCtrl.text.isEmpty) return;
      corps = {
        'name': _nomCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _mdpCtrl.text,
        'relationship_type': _lien,
      };
    }
    Navigator.pop(context, corps);
  }

  @override
  Widget build(BuildContext context) {
    final peutValider = _parentExistant
        ? _selectionne != null
        : _nomCtrl.text.trim().isNotEmpty && _emailCtrl.text.trim().isNotEmpty && _mdpCtrl.text.isNotEmpty;

    return AlertDialog(
      title: const Text('Ajouter un parent'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Parent existant')),
                  ButtonSegment(value: false, label: Text('Nouveau parent')),
                ],
                selected: {_parentExistant},
                onSelectionChanged: (s) => setState(() => _parentExistant = s.first),
              ),
              const SizedBox(height: 16),

              if (_parentExistant) ...[
                TextField(
                  controller: _rechercheCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rechercher (nom ou e-mail)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    setState(() => _selectionne = null);
                    _surChangementRecherche(v);
                  },
                ),
                const SizedBox(height: 8),
                if (_recherche)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_resultats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Aucun parent trouvé.', style: TextStyle(color: AppColors.muted)),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _resultats.length,
                      itemBuilder: (_, i) {
                        final p = _resultats[i];
                        final selectionne = p.id == _selectionne?.id;
                        return ListTile(
                          dense: true,
                          selected: selectionne,
                          selectedTileColor: AppColors.light,
                          title: Text(p.name),
                          subtitle: Text(p.email),
                          trailing: selectionne ? const Icon(Icons.check_circle, color: AppColors.green) : null,
                          onTap: () => setState(() => _selectionne = p),
                        );
                      },
                    ),
                  ),
              ] else ...[
                TextField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (_) => setState(() {}),
                ),
                TextField(
                  controller: _mdpCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _lien,
                decoration: const InputDecoration(labelText: 'Lien de parenté'),
                items: const [
                  DropdownMenuItem(value: 'mère', child: Text('Mère')),
                  DropdownMenuItem(value: 'père', child: Text('Père')),
                  DropdownMenuItem(value: 'tuteur', child: Text('Tuteur/tutrice')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
                onChanged: (v) => setState(() => _lien = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: peutValider ? _valider : null, child: const Text('Ajouter')),
      ],
    );
  }
}
