import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/announcement_service.dart';
import '../../widgets/success_toast.dart';

/// Publication d'une annonce par le personnel, ciblée sur toute l'école ou
/// une classe précise (docs/PRODUCT_ARCHITECTURE.md §8).
class NouveauMessageScreen extends StatefulWidget {
  const NouveauMessageScreen({super.key});

  @override
  State<NouveauMessageScreen> createState() => _NouveauMessageScreenState();
}

class _NouveauMessageScreenState extends State<NouveauMessageScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _corpsCtrl = TextEditingController();
  final _announcementService = AnnouncementService();

  String _categorie = 'info';
  int? _classeCiblee; // null = toute l'école
  bool _envoi = false;

  static const _categories = {
    'info':     'Information',
    'reunion':  'Réunion',
    'sortie':   'Sortie scolaire',
    'examen':   'Examen',
    'vacances': 'Vacances',
    'urgence':  'Urgent',
  };

  @override
  void dispose() {
    _titreCtrl.dispose();
    _corpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      await _announcementService.publierAnnonce(
        title: _titreCtrl.text.trim(),
        body: _corpsCtrl.text.trim(),
        category: _categorie,
        targets: _classeCiblee == null
            ? [{'target_type': 'all'}]
            : [{'target_type': 'school_class', 'target_id': _classeCiblee}],
      );
      if (mounted) {
        showSuccessToast(context, 'Annonce publiée.');
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
    final classes = context.read<AuthProvider>().user?.classes ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle annonce')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _categorie = v!),
              ),
              const SizedBox(height: 12),
              if (classes.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _classeCiblee,
                  decoration: const InputDecoration(labelText: 'Destinataires'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toute l\'école')),
                    ...classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _classeCiblee = v),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titreCtrl,
                decoration: const InputDecoration(labelText: 'Titre *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _corpsCtrl,
                decoration: const InputDecoration(labelText: 'Contenu *'),
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty ? 'Le contenu est requis' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _envoi ? null : _envoyer,
                child: _envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('Publier l\'annonce'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
