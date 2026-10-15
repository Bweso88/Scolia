import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../config/theme.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../services/children_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/archivable_tile.dart';
import '../../widgets/empty_state.dart';

/// Annonces de l'école (docs/PRODUCT_ARCHITECTURE.md §8) : le cahier de
/// liaison "officiel" de l'établissement, ciblé sur tous, une classe ou un
/// parent en particulier.
class LiaisonScreen extends StatefulWidget {
  const LiaisonScreen({super.key});

  @override
  State<LiaisonScreen> createState() => _LiaisonScreenState();
}

class _LiaisonScreenState extends State<LiaisonScreen> {
  final _childrenService = ChildrenService();
  final _announcementService = AnnouncementService();

  List<Announcement> _annonces = [];
  bool _charge = false;
  int? _dernierEnfantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _archiver(Announcement a) async {
    setState(() => _annonces.removeWhere((x) => x.id == a.id));
    try {
      await _announcementService.archiverAnnonce(a.id);
    } catch (_) {
      if (mounted) setState(() => _annonces.add(a));
    }
  }

  Future<void> _supprimer(Announcement a) async {
    setState(() => _annonces.removeWhere((x) => x.id == a.id));
    try {
      await _announcementService.supprimerAnnonce(a.id);
    } catch (e) {
      if (mounted) {
        setState(() => _annonces.add(a));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  Future<void> _charger() async {
    final user = context.read<AuthProvider>().user;
    setState(() => _charge = true);
    try {
      if (user?.estParent == true) {
        final enfant = context.read<ChildProvider>().selectionne;
        if (enfant == null) return;
        _annonces = await _childrenService.getAnnonces(enfant.id);
        _dernierEnfantId = enfant.id;
      } else {
        _annonces = await _announcementService.getAnnonces();
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
    final peutPublier = auth.user?.estAdmin == true || auth.user?.estEnseignant == true;

    if (estParent) {
      final enfant = context.watch<ChildProvider>().selectionne;
      if (enfant != null && enfant.id != _dernierEnfantId && !_charge) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        actions: [
          if (peutPublier)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.white),
              onPressed: () async {
                final publie = await context.push<bool>('/liaison/nouveau');
                if (publie == true) _charger();
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
                  : _annonces.isEmpty
                      ? EmptyState(
                          message: 'Aucune annonce',
                          sousTitre: 'Les annonces de l\'école apparaîtront ici.',
                          icone: Icons.campaign_outlined,
                          onAction: _charger,
                          libelleAction: 'Actualiser',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _annonces.length,
                          itemBuilder: (_, i) {
                            final a = _annonces[i];
                            return AnimatedEntry(
                              index: i,
                              child: ArchivableTile(
                                cle: a.id,
                                onArchiver: () => _archiver(a),
                                onSupprimer: () => _supprimer(a),
                                child: AnnouncementCard(announcement: a),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 3),
    );
  }
}
