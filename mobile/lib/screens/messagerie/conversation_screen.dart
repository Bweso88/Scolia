import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/message_app.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';

/// Fil de discussion d'une conversation (docs/PRODUCT_ARCHITECTURE.md §7).
/// Un parent ne peut plus répondre passé l'heure limite de l'école ; le
/// personnel n'y est jamais soumis.
class ConversationScreen extends StatefulWidget {
  final int conversationId;
  final String titre;

  const ConversationScreen({super.key, required this.conversationId, required this.titre});

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

  @override
  Widget build(BuildContext context) {
    final moi = context.read<AuthProvider>().user!.id;
    final estParent = context.read<AuthProvider>().user?.estParent == true;
    final tenant = context.read<AuthProvider>().user?.tenant;
    final fermee = estParent && (tenant?.messagerieFermee ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
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
                      return Align(
                        alignment: deMoi ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: deMoi ? AppColors.navy : AppColors.light,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!deMoi && m.senderName != null)
                                Text(m.senderName!, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                              Text(m.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: deMoi ? AppColors.white : AppColors.body)),
                            ],
                          ),
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
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _corpsCtrl,
                            decoration: const InputDecoration(hintText: 'Votre message...'),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _envoi ? null : _envoyer,
                          icon: _envoi
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.navy),
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
