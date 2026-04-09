import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/liaison_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/message_card.dart';
import '../../widgets/empty_state.dart';

class LiaisonScreen extends StatefulWidget {
  const LiaisonScreen({super.key});

  @override
  State<LiaisonScreen> createState() => _LiaisonScreenState();
}

class _LiaisonScreenState extends State<LiaisonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiaisonProvider>().charger(recharger: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final liaison = context.watch<LiaisonProvider>();
    final peutEcrire = auth.user?.estParent == false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cahier de liaison'),
        actions: [
          if (peutEcrire)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () => context.push('/liaison/nouveau'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => liaison.charger(recharger: true),
        child: liaison.charge && liaison.messages.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : liaison.messages.isEmpty
                ? EmptyState(
                    message: 'Aucun message',
                    sousTitre: 'Les messages de liaison apparaîtront ici.',
                    icone: Icons.menu_book_outlined,
                    onAction: () => liaison.charger(recharger: true),
                    libelleAction: 'Actualiser',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: liaison.messages.length + (liaison.aPlus ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == liaison.messages.length) {
                        liaison.charger();
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return MessageCard(message: liaison.messages[i]);
                    },
                  ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 1),
    );
  }
}
