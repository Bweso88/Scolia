import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/eleve.dart';
import '../../models/matiere.dart';
import '../../models/periode.dart';
import '../../services/api_service.dart';
import '../../services/notes_service.dart';

class SaisirNoteScreen extends StatefulWidget {
  final int? eleveId;
  const SaisirNoteScreen({super.key, this.eleveId});

  @override
  State<SaisirNoteScreen> createState() => _SaisirNoteScreenState();
}

class _SaisirNoteScreenState extends State<SaisirNoteScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _noteCtrl   = TextEditingController();
  final _surCtrl    = TextEditingController(text: '20');
  final _commentCtrl = TextEditingController();
  final _notesService = NotesService();

  List<Eleve>   _eleves   = [];
  List<Matiere> _matieres = [];
  List<Periode> _periodes = [];

  int?    _eleveSelectionne;
  int?    _matiereSelectionnee;
  int?    _periodeSelectionnee;
  String  _typeEval = 'controle';
  bool    _charge   = false;
  bool    _envoi    = false;

  @override
  void initState() {
    super.initState();
    _eleveSelectionne = widget.eleveId;
    _chargerDonnees();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _surCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _charge = true);
    try {
      final results = await Future.wait([
        apiService.get('/eleves'),
        _notesService.getPeriodes(),
        _notesService.getMatieres(),
      ]);
      setState(() {
        _eleves   = ((results[0] as Map)['items'] as List)
            .map((e) => Eleve.fromJson(e as Map<String, dynamic>))
            .toList();
        _periodes = results[1] as List<Periode>;
        _matieres = results[2] as List<Matiere>;
      });
    } catch (_) {
    } finally {
      setState(() => _charge = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eleveSelectionne == null || _matiereSelectionnee == null || _periodeSelectionnee == null) {
      _snack('Tous les champs obligatoires sont requis.', AppColors.orange);
      return;
    }

    final note = double.tryParse(_noteCtrl.text.trim());
    final sur  = double.tryParse(_surCtrl.text.trim()) ?? 20;
    if (note == null || note < 0 || note > sur) {
      _snack('Note invalide (doit être entre 0 et $sur).', AppColors.orange);
      return;
    }

    setState(() => _envoi = true);
    try {
      await _notesService.saisirNote({
        'eleve_id':        _eleveSelectionne,
        'matiere_id':      _matiereSelectionnee,
        'periode_id':      _periodeSelectionnee,
        'note':            note,
        'note_sur':        sur,
        'commentaire':     _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        'type_evaluation': _typeEval,
        'date_evaluation': DateTime.now().toIso8601String().substring(0, 10),
      });
      if (mounted) {
        _snack('Note enregistrée.', AppColors.green);
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.red);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saisir une note')),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionTitre('Élève et matière'),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<int>(
                      value: _eleveSelectionne,
                      decoration: const InputDecoration(labelText: 'Élève *'),
                      items: _eleves.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nomComplet))).toList(),
                      onChanged: (v) => setState(() => _eleveSelectionne = v),
                      validator: (v) => v == null ? 'Sélectionnez un élève' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _matiereSelectionnee,
                      decoration: const InputDecoration(labelText: 'Matière *'),
                      items: _matieres.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.nom} (coeff. ${m.coefficient.toStringAsFixed(1)})'),
                      )).toList(),
                      onChanged: (v) => setState(() => _matiereSelectionnee = v),
                      validator: (v) => v == null ? 'Sélectionnez une matière' : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _periodeSelectionnee,
                      decoration: const InputDecoration(labelText: 'Période *'),
                      items: _periodes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom))).toList(),
                      onChanged: (v) => setState(() => _periodeSelectionnee = v),
                      validator: (v) => v == null ? 'Sélectionnez une période' : null,
                    ),

                    const SizedBox(height: 20),
                    _SectionTitre('Note'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _noteCtrl,
                            decoration: const InputDecoration(labelText: 'Note obtenue *'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              if (double.tryParse(v.trim()) == null) return 'Nombre invalide';
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('/', style: GoogleFonts.plusJakartaSans(fontSize: 22, color: AppColors.muted)),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _surCtrl,
                            decoration: const InputDecoration(labelText: 'Sur'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _typeEval,
                      decoration: const InputDecoration(labelText: "Type d'évaluation"),
                      items: const [
                        DropdownMenuItem(value: 'controle', child: Text('Contrôle')),
                        DropdownMenuItem(value: 'devoir',   child: Text('Devoir')),
                        DropdownMenuItem(value: 'examen',   child: Text('Examen')),
                        DropdownMenuItem(value: 'oral',     child: Text('Oral')),
                        DropdownMenuItem(value: 'autre',    child: Text('Autre')),
                      ],
                      onChanged: (v) => setState(() => _typeEval = v!),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Commentaire (facultatif)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _envoi ? null : _enregistrer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _envoi
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : Text('Enregistrer la note',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionTitre extends StatelessWidget {
  final String texte;
  const _SectionTitre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(texte,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5));
  }
}
