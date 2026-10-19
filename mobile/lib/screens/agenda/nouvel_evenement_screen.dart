import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/academic_event.dart';
import '../../services/academic_event_service.dart';
import '../../widgets/success_toast.dart';

/// Publication d'un événement du calendrier scolaire par la direction
/// (docs/PRODUCT_ARCHITECTURE.md — écran "Agenda").
class NouvelEvenementScreen extends StatefulWidget {
  const NouvelEvenementScreen({super.key});

  @override
  State<NouvelEvenementScreen> createState() => _NouvelEvenementScreenState();
}

class _NouvelEvenementScreenState extends State<NouvelEvenementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _service = AcademicEventService();

  String _categorie = 'evenement';
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _envoi = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: debut ? _dateDebut : (_dateFin ?? _dateDebut),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (choisie != null) {
      setState(() {
        if (debut) {
          _dateDebut = choisie;
        } else {
          _dateFin = choisie;
        }
      });
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await _service.creerEvenement({
        'title': _titreCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        'category': _categorie,
        'start_date': _dateDebut.toIso8601String().substring(0, 10),
        'end_date': (_dateFin ?? _dateDebut).toIso8601String().substring(0, 10),
      });
      if (mounted) {
        showSuccessToast(context, 'Événement publié.');
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

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel événement')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: categoriesEvenement.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
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
                decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _choisirDate(debut: true),
                      child: Text('Début : ${_formatDate(_dateDebut)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _choisirDate(debut: false),
                      child: Text('Fin : ${_formatDate(_dateFin ?? _dateDebut)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _envoi ? null : _enregistrer,
                child: _envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('Publier l\'événement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
