import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/message_app.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';
import '../../widgets/animated_entry.dart';

/// Fil de discussion d'une conversation (docs/PRODUCT_ARCHITECTURE.md §7).
/// Un parent ne peut plus répondre passé l'heure limite de l'école ; le
/// personnel n'y est jamais soumis.
class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String titre;
  final String? sousTitre;

  const ConversationScreen({super.key, required this.conversationId, required this.titre, this.sousTitre});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _corpsCtrl = TextEditingController();
  final _service = MessagingService();
  final _scrollCtrl = ScrollController();

  List<MessageApp> _messages = [];
  bool _charge = false;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _corpsCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _messages = await _service.getMessages(widget.conversationId);
      WidgetsBinding.instance.addPostFrameCallback((_) => _defilerEnBas());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  void _defilerEnBas() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _envoyer() async {
    final texte = _corpsCtrl.text.trim();
    if (texte.isEmpty) return;
    setState(() => _envoi = true);
    try {
      await _service.envoyerMessage(widget.conversationId, texte);
      _corpsCtrl.clear();
      await _charger();
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

  /// Jour (sans l'heure) d'un message, pour détecter un changement de
  /// journée dans la liste et y insérer un séparateur — null si le
  /// message n'a pas de date (ne doit jamais arriver en pratique).
  DateTime? _jourDe(String? createdAt) {
    if (createdAt == null) return null;
    final d = DateTime.parse(createdAt).toLocal();
    return DateTime(d.year, d.month, d.day);
  }

  String _libelleJour(DateTime jour) {
    final maintenant = DateTime.now();
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final hier = aujourdhui.subtract(const Duration(days: 1));
    if (jour == aujourdhui) return "Aujourd'hui";
    if (jour == hier) return 'Hier';
    return DateFormat('d MMMM y', 'fr_FR').format(jour);
  }

  Widget _separateurJour(String createdAt) {
    final jour = _jourDe(createdAt)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(20)),
          child: Text(
            _libelleJour(jour),
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _avatarInitiales(String? nom) {
    final initiales = (nom == null || nom.trim().isEmpty)
        ? '?'
        : nom.trim().split(RegExp(r'\s+')).take(2).map((m) => m[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.navy.withOpacity(0.12),
      child: Text(initiales, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moi = context.read<AuthProvider>().user!.id;
    final estParent = context.read<AuthProvider>().user?.estParent == true;
    final tenant = context.read<AuthProvider>().user?.tenant;
    final fermee = estParent && (tenant?.messagerieFermee ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titre),
        bottom: widget.sousTitre != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.sousTitre!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.white.withOpacity(0.8)),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: _charge
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final deMoi = m.senderId == moi;
                      final precedent = i > 0 ? _messages[i - 1] : null;
                      final nouveauJour = _jourDe(m.createdAt) != _jourDe(precedent?.createdAt);

                      return AnimatedEntry(
                        index: i,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (nouveauJour && _jourDe(m.createdAt) != null) _separateurJour(m.createdAt!),
                            Align(
                              alignment: deMoi ? Alignment.centerRight : Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!deMoi) ...[
                                    _avatarInitiales(m.senderName),
                                    const SizedBox(width: 8),
                                  ],
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: deMoi ? AppColors.navy : AppColors.light,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(deMoi ? 16 : 4),
                                          bottomRight: Radius.circular(deMoi ? 4 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (deMoi ? AppColors.navy : AppColors.navy.withOpacity(0.5)).withOpacity(0.08),
                                            blurRadius: 8, offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!deMoi && m.senderName != null)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Text(m.senderName!,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                                            ),
                                          Text(m.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: deMoi ? AppColors.white : AppColors.body)),
                                          if (m.createdAt != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                DateFormat('HH:mm', 'fr_FR').format(DateTime.parse(m.createdAt!).toLocal()),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: deMoi ? AppColors.white.withOpacity(0.55) : AppColors.muted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: fermee
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        'Messagerie fermée pour aujourd\'hui (heure limite : ${tenant?.messagingCutoffTime?.substring(0, 5)}).',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.body),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: TextField(
                              controller: _corpsCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Votre message...',
                                border: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              minLines: 1,
                              maxLines: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _envoi ? null : _envoyer,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 46, height: 46,
                            decoration: const BoxDecoration(color: AppColors.navy, shape: BoxShape.circle),
                            child: _envoi
                                ? const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_upward_rounded, color: AppColors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
