import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/messaging_contact.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../services/messaging_service.dart';
import '../../widgets/success_toast.dart';

/// Un parent choisit l'enfant concerné puis un destinataire (le professeur
/// de sa classe, ou la direction) — docs/PRODUCT_ARCHITECTURE.md §7. La
/// liste des destinataires vient du serveur : elle ne montre jamais un
/// enseignant qui n'enseigne pas dans la classe de cet enfant.
class NouvelleConversationScreen extends StatefulWidget {
  const NouvelleConversationScreen({super.key});

  @override
  State<NouvelleConversationScreen> createState() => _NouvelleConversationScreenState();
}

class _NouvelleConversationScreenState extends State<NouvelleConversationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sujetCtrl = TextEditingController();
  final _corpsCtrl = TextEditingController();
  final _service = MessagingService();

  int? _enfantId;
  List<MessagingContact> _profs = [];
  List<MessagingContact> _direction = [];
  int? _destinataireId;
  bool _charge = false;
  bool _envoi = false;
  String? _erreurChargement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final enfant = context.read<ChildProvider>().selectionne;
      if (enfant != null) {
        _enfantId = enfant.id;
        _chargerContacts();
      }
    });
  }

  @override
  void dispose() {
    _sujetCtrl.dispose();
    _corpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerContacts() async {
    if (_enfantId == null) return;
    setState(() {
      _charge = true;
      _erreurChargement = null;
      _destinataireId = null;
    });
    try {
      final contacts = await _service.getContacts(_enfantId!);
      setState(() {
        _profs = contacts.profs;
        _direction = contacts.direction;
      });
    } on Exception catch (e) {
      setState(() => _erreurChargement = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinataireId == null) {
      _snack('Choisissez un destinataire.', AppColors.orange);
      return;
    }
    setState(() => _envoi = true);
    try {
      await _service.creerConversation(
        participantUserId: _destinataireId!,
        body: _corpsCtrl.text.trim(),
        subject: _sujetCtrl.text.trim(),
        studentId: _enfantId,
      );
      if (mounted) {
        showSuccessToast(context, 'Message envoyé.');
        context.pop(true);
      }
    } on Exception catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.red);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final enfants = context.watch<ChildProvider>().enfants;
    final tenant = context.read<AuthProvider>().user?.tenant;
    final fermee = tenant?.messagerieFermee ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fermee)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    'La messagerie est fermée pour aujourd\'hui (heure limite : ${tenant?.messagingCutoffTime?.substring(0, 5)}). Vous pourrez écrire demain.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.body),
                  ),
                ),

              if (enfants.length > 1)
                DropdownButtonFormField<int>(
                  initialValue: _enfantId,
                  decoration: const InputDecoration(labelText: 'Concernant *'),
                  items: enfants.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nomComplet))).toList(),
                  onChanged: (v) {
                    setState(() => _enfantId = v);
                    _chargerContacts();
                  },
                  validator: (v) => v == null ? 'Sélectionnez un enfant' : null,
                ),
              if (enfants.length > 1) const SizedBox(height: 12),

              if (_charge)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (_erreurChargement != null)
                Text(_erreurChargement!, style: const TextStyle(color: AppColors.red))
              else ...[
                Text('Destinataire *', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 8),
                ..._profs.map((c) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: c.userId,
                      groupValue: _destinataireId,
                      onChanged: c.contactable ? (v) => setState(() => _destinataireId = v) : null,
                      title: Text(c.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        c.contactable ? (c.subject ?? 'Professeur') : 'Non joignable directement — passez par la direction',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: c.contactable ? AppColors.muted : AppColors.orange),
                      ),
                    )),
                ..._direction.map((c) => RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      value: c.userId,
                      groupValue: _destinataireId,
                      onChanged: (v) => setState(() => _destinataireId = v),
                      title: Text(c.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('Direction', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                    )),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _sujetCtrl,
                decoration: const InputDecoration(labelText: 'Objet (facultatif)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _corpsCtrl,
                decoration: const InputDecoration(labelText: 'Message *', alignLabelWithHint: true),
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty ? 'Le message est requis' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_envoi || fermee) ? null : _envoyer,
                child: _envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('Envoyer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
