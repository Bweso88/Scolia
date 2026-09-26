import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';
import '../../widgets/empty_state.dart';

/// Liste des fils de discussion de l'utilisateur connecté — un parent y
/// écrit au prof de son enfant ou à la direction (docs/PRODUCT_ARCHITECTURE.md
/// §7) ; le personnel y répond.
class MessagerieScreen extends StatefulWidget {
  const MessagerieScreen({super.key});

  @override
  State<MessagerieScreen> createState() => _MessagerieScreenState();
}

class _MessagerieScreenState extends State<MessagerieScreen> {
  final _service = MessagingService();
  List<Conversation> _conversations = [];
  bool _charge = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _charge = true);
    try {
      _conversations = await _service.getConversations();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estParent = context.read<AuthProvider>().user?.estParent == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _charge
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? EmptyState(
                    message: 'Aucune conversation',
                    sousTitre: estParent
                        ? 'Écrivez au professeur de votre enfant ou à la direction.'
                        : 'Les messages des parents apparaîtront ici.',
                    icone: Icons.forum_outlined,
                    onAction: _charger,
                    libelleAction: 'Actualiser',
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) {
                      final c = _conversations[i];
                      final moi = context.read<AuthProvider>().user!.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.navy.withOpacity(0.1),
                          child: const Icon(Icons.person_outline, color: AppColors.navy),
                        ),
                        title: Text(c.interlocuteur(moi), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(
                          c.lastMessage ?? c.subject ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                        ),
                        onTap: () async {
                          await context.push('/messagerie/conversation', extra: {'id': c.id, 'titre': c.interlocuteur(moi)});
                          _charger();
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: estParent
          ? FloatingActionButton.extended(
              onPressed: () async {
                final envoye = await context.push<bool>('/messagerie/nouvelle');
                if (envoye == true) _charger();
              },
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: Text('Nouveau message', style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}
