import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/homework.dart';
import '../../models/note.dart';
import '../../models/periode.dart';
import '../../models/student.dart';
import '../../services/notes_service.dart';
import '../../services/student_service.dart';
import '../../widgets/success_toast.dart';

/// Permet à un enseignant de noter d'un coup toute la classe sur un devoir
/// donné : une ligne par élève, une note chacun, rattachées au devoir
/// (grades.homework_id) — plutôt que de ressaisir matière/période à la
/// main pour chaque élève comme sur l'écran de saisie générique.
class NoterDevoirScreen extends StatefulWidget {
  final Homework devoir;
  const NoterDevoirScreen({super.key, required this.devoir});

  @override
  State<NoterDevoirScreen> createState() => _NoterDevoirScreenState();
}

class _NoterDevoirScreenState extends State<NoterDevoirScreen> {
  final _studentService = StudentService();
  final _notesService = NotesService();

  final Map<int, TextEditingController> _controleurs = {};
  final _surCtrl = TextEditingController(text: '20');

  List<Student> _eleves = [];
  List<Periode> _periodes = [];
  Map<int, Note> _notesExistantes = {};
  int? _periodeSelectionnee;
  String _typeSelectionne = 'devoir';
  bool _charge = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    for (final c in _controleurs.values) {
      c.dispose();
    }
    _surCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _charge = true);
    try {
      final results = await Future.wait([
        _studentService.getEleves(schoolClassId: widget.devoir.schoolClassId),
        _notesService.getPeriodes(),
        _notesService.getNotesDeLaClasse(homeworkId: widget.devoir.id),
      ]);
      final eleves = results[0] as List<Student>;
      final notes = (results[2] as List<Note>);
      setState(() {
        _eleves = eleves;
        _periodes = results[1] as List<Periode>;
        _periodeSelectionnee = _periodes.isNotEmpty ? _periodes.last.id : null;
        _notesExistantes = {for (final n in notes) if (n.studentId != null) n.studentId!: n};
        for (final e in eleves) {
          final existante = _notesExistantes[e.id];
          _controleurs[e.id] = TextEditingController(text: existante != null ? existante.score.toStringAsFixed(1) : '');
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _enregistrer() async {
    if (widget.devoir.subjectId == null || _periodeSelectionnee == null) return;
    final sur = double.tryParse(_surCtrl.text.trim()) ?? 20;

    final aEnregistrer = <(int, double)>[];
    for (final e in _eleves) {
      final texte = _controleurs[e.id]?.text.trim() ?? '';
      if (texte.isEmpty) continue;
      final valeur = double.tryParse(texte);
      if (valeur == null || valeur < 0 || valeur > sur) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Note invalide pour ${e.nomComplet} (doit être entre 0 et $sur).'),
          backgroundColor: AppColors.red,
        ));
        return;
      }
      aEnregistrer.add((e.id, valeur));
    }

    if (aEnregistrer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez au moins une note.'), backgroundColor: AppColors.orange),
      );
      return;
    }

    setState(() => _envoi = true);
    try {
      await Future.wait(aEnregistrer.map((entree) => _notesService.saisirNote({
            'student_id': entree.$1,
            'subject_id': widget.devoir.subjectId,
            'homework_id': widget.devoir.id,
            'grading_period_id': _periodeSelectionnee,
            'type': _typeSelectionne,
            'score': entree.$2,
            'max_score': sur,
            'coefficient': 1,
          })));
      if (mounted) {
        showSuccessToast(context, '${aEnregistrer.length} note${aEnregistrer.length > 1 ? "s" : ""} enregistrée${aEnregistrer.length > 1 ? "s" : ""}.');
        context.pop(true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Noter le devoir'),
            Text(widget.devoir.title, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.white.withOpacity(0.75))),
          ],
        ),
      ),
      body: _charge
          ? const Center(child: CircularProgressIndicator())
          : _periodes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Aucune période de notation n\'a encore été créée pour cette école. Contactez l\'administration.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _periodeSelectionnee,
                                  decoration: const InputDecoration(labelText: 'Période'),
                                  items: _periodes.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom))).toList(),
                                  onChanged: (v) => setState(() => _periodeSelectionnee = v),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 90,
                                child: TextFormField(
                                  controller: _surCtrl,
                                  decoration: const InputDecoration(labelText: 'Sur'),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _typeSelectionne,
                            decoration: const InputDecoration(labelText: 'Type d\'évaluation'),
                            items: typesNote.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                            onChanged: (v) => setState(() => _typeSelectionne = v!),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _eleves.isEmpty
                          ? Center(
                              child: Text('Aucun élève dans cette classe.', style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _eleves.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final e = _eleves[i];
                                final dejaNotee = _notesExistantes.containsKey(e.id);
                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.blue.withOpacity(0.1),
                                      child: Text(
                                        e.firstName.isNotEmpty ? e.firstName[0].toUpperCase() : '?',
                                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.blue),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.nomComplet, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.navy)),
                                          if (dejaNotee)
                                            Text('Déjà notée — modification possible', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.muted)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 72,
                                      child: TextField(
                                        controller: _controleurs[e.id],
                                        textAlign: TextAlign.center,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: '—',
                                          suffixText: '/${_surCtrl.text}',
                                          suffixStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _envoi ? null : _enregistrer,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: _envoi
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                            : Text('Enregistrer les notes', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
    );
  }
}
