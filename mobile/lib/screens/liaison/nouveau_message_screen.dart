import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/liaison_provider.dart';
import '../../config/theme.dart';

class NouveauMessageScreen extends StatefulWidget {
  const NouveauMessageScreen({super.key});

  @override
  State<NouveauMessageScreen> createState() => _NouveauMessageScreenState();
}

class _NouveauMessageScreenState extends State<NouveauMessageScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _contenuCtrl = TextEditingController();
  String _categorie   = 'info';
  bool _necessite_ack = false;
  bool _envoi = false;

  static const _categories = ['info', 'devoir', 'autorisation', 'retard', 'autre'];

  @override
  void dispose() {
    _titreCtrl.dispose();
    _contenuCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await context.read<LiaisonProvider>().creerMessage({
        'titre':        _titreCtrl.text.trim(),
        'contenu':      _contenuCtrl.text.trim(),
        'categorie':    _categorie,
        'necessite_ack': _necessite_ack,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message publié.'), backgroundColor: AppColors.green),
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
      appBar: AppBar(title: const Text('Nouveau message')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categorie = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titreCtrl,
                decoration: const InputDecoration(labelText: 'Titre (optionnel)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contenuCtrl,
                decoration: const InputDecoration(labelText: 'Contenu *'),
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty ? 'Le contenu est requis' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Demander un accusé de réception'),
                value: _necessite_ack,
                onChanged: (v) => setState(() => _necessite_ack = v),
                activeColor: AppColors.navy,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _envoi ? null : _envoyer,
                child: _envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('Publier le message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
