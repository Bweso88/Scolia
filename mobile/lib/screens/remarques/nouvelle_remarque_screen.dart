import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/remarques_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/eleve.dart';

class NouvelleRemarqueScreen extends StatefulWidget {
  final int? eleveId;
  const NouvelleRemarqueScreen({super.key, this.eleveId});

  @override
  State<NouvelleRemarqueScreen> createState() => _NouvelleRemarqueScreenState();
}

class _NouvelleRemarqueScreenState extends State<NouvelleRemarqueScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _msgCtrl    = TextEditingController();
  String _categorie = 'autre';
  String _priorite  = 'info';
  int? _eleveSelectionne;
  List<Eleve> _eleves = [];
  bool _charge = false;
  bool _envoi  = false;

  @override
  void initState() {
    super.initState();
    _eleveSelectionne = widget.eleveId;
    _chargerEleves();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerEleves() async {
    setState(() => _charge = true);
    try {
      final data = await apiService.get('/eleves');
      setState(() {
        _eleves = (data['items'] as List)
            .map((e) => Eleve.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _charge = false);
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
      await context.read<RemarquesProvider>().creerRemarque({
        'eleve_id':  _eleveSelectionne,
        'message':   _msgCtrl.text.trim(),
        'categorie': _categorie,
        'priorite':  _priorite,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remarque créée.'), backgroundColor: AppColors.green),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle remarque')),
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
                      items: const [
                        DropdownMenuItem(value: 'felicitation', child: Text('Félicitation')),
                        DropdownMenuItem(value: 'comportement', child: Text('Comportement')),
                        DropdownMenuItem(value: 'absence',      child: Text('Absence')),
                        DropdownMenuItem(value: 'retard',       child: Text('Retard')),
                        DropdownMenuItem(value: 'sante',        child: Text('Santé')),
                        DropdownMenuItem(value: 'autre',        child: Text('Autre')),
                      ],
                      onChanged: (v) => setState(() => _categorie = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _priorite,
                      decoration: const InputDecoration(labelText: 'Priorité'),
                      items: const [
                        DropdownMenuItem(value: 'info',          child: Text('Information')),
                        DropdownMenuItem(value: 'avertissement', child: Text('Avertissement')),
                        DropdownMenuItem(value: 'urgent',        child: Text('Urgent')),
                      ],
                      onChanged: (v) => setState(() => _priorite = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(labelText: 'Message *'),
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Le message est requis' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _envoi ? null : _envoyer,
                      child: _envoi
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Envoyer la remarque'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
