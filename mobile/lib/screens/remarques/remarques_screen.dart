import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/remarques_provider.dart';
import '../../config/theme.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/remarque_card.dart';
import '../../widgets/empty_state.dart';

class RemarquesScreen extends StatefulWidget {
  const RemarquesScreen({super.key});

  @override
  State<RemarquesScreen> createState() => _RemarquesScreenState();
}

class _RemarquesScreenState extends State<RemarquesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemarquesProvider>().charger(recharger: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final remarques = context.watch<RemarquesProvider>();
    final peutEcrire = auth.user?.estParent == false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remarques'),
        actions: [
          if (peutEcrire)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () => context.push('/remarques/nouvelle'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => remarques.charger(recharger: true),
        child: remarques.charge && remarques.remarques.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : remarques.remarques.isEmpty
                ? EmptyState(
                    message: 'Aucune remarque',
                    sousTitre: 'Les remarques pédagogiques apparaîtront ici.',
                    icone: Icons.comment_outlined,
                    onAction: () => remarques.charger(recharger: true),
                    libelleAction: 'Actualiser',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: remarques.remarques.length,
                    itemBuilder: (_, i) => RemarqueCard(remarque: remarques.remarques[i]),
                  ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 2),
    );
  }
}
