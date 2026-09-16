import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../config/theme.dart';
import '../../models/remarque.dart';
import '../../services/children_service.dart';
import '../../services/remarques_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/remarque_card.dart';
import '../../widgets/empty_state.dart';

/// Comportement (docs/PRODUCT_ARCHITECTURE.md §5) : historique des
/// observations, publication réservée au personnel.
class RemarquesScreen extends StatefulWidget {
  const RemarquesScreen({super.key});

  @override
  State<RemarquesScreen> createState() => _RemarquesScreenState();
}

class _RemarquesScreenState extends State<RemarquesScreen> {
  final _childrenService = ChildrenService();
  final _remarquesService = RemarquesService();

  List<Remarque> _remarques = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _charge = true);
    try {
      if (user?.estParent == true) {
        final enfant = context.read<ChildProvider>().selectionne;
        if (enfant == null) return;
        _remarques = await _childrenService.getComportement(enfant.id);
        _dernierEnfantId = enfant.id;
      } else {
        _remarques = await _remarquesService.getRemarques();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _charge = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estParent = auth.user?.estParent == true;
    final peutEcrire = auth.user?.faitPartieDuPersonnel == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comportement'),
        actions: [
          if (peutEcrire)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () async {
                final cree = await context.push<bool>('/remarques/nouvelle');
                if (cree == true) _charger();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (estParent) ...[
            const SizedBox(height: 12),
            const ChildSelector(),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: _charger,
              child: _charge
                  ? const Center(child: CircularProgressIndicator())
                  : _remarques.isEmpty
                      ? EmptyState(
                          message: 'Aucune observation',
                          sousTitre: 'Les observations de comportement apparaîtront ici.',
                          icone: Icons.comment_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _remarques.length,
                          itemBuilder: (_, i) => RemarqueCard(remarque: _remarques[i]),
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 2),
    );
  }
}
