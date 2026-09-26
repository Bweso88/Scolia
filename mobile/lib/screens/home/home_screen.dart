import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../config/theme.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/child_selector.dart';
import '../../widgets/empty_state.dart';
import '../../services/children_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _childrenService = ChildrenService();
  Map<String, dynamic>? _dashboard;
  bool _chargeDashboard = false;
  int? _dernierEnfantCharge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    context.read<NotificationsProvider>().charger();

    final user = context.read<AuthProvider>().user;
    if (user?.estParent != true) return;

    final enfants = context.read<ChildProvider>();
    await enfants.charger();
    await _chargerDashboard();
  }

  Future<void> _chargerDashboard() async {
    final enfant = context.read<ChildProvider>().selectionne;
    if (enfant == null) return;
    setState(() => _chargeDashboard = true);
    try {
      final data = await _childrenService.getDashboard(enfant.id);
      setState(() {
        _dashboard = data;
        _dernierEnfantCharge = enfant.id;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chargeDashboard = false);
    }
  }

  static String _initiales(String? nom) {
    if (nom == null || nom.trim().isEmpty) return '?';
    final mots = nom.trim().split(RegExp(r'\s+'));
    final lettres = mots.take(2).map((m) => m[0].toUpperCase()).join();
    return lettres;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final branding = user?.tenant;

    // Le tableau de bord suit le changement d'enfant sélectionné.
    final enfantCourant = context.watch<ChildProvider>().selectionne;
    if (user?.estParent == true && enfantCourant != null && enfantCourant.id != _dernierEnfantCharge && !_chargeDashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chargerDashboard());
    }

    final couleurPrimaire = branding?.primaryColor ?? AppColors.navy;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _charger,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _entete(context, user, branding, couleurPrimaire)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user?.estParent == true) ..._sectionParent(context, user),
                    if (user?.faitPartieDuPersonnel == true) ..._sectionPersonnel(context, user),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 0),
    );
  }

  Widget _entete(BuildContext context, dynamic user, dynamic branding, Color couleurPrimaire) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 26),
      decoration: BoxDecoration(
        color: couleurPrimaire,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: couleurPrimaire.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withOpacity(0.4), width: 1.5),
            ),
            child: branding?.logoUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: branding.logoUrl!,
                      errorWidget: (_, __, ___) => _initialesWidget(user?.name),
                    ),
                  )
                : _initialesWidget(user?.name),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branding?.displayName ?? 'Scolia',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Bonjour, ${user?.name ?? ''}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.white.withOpacity(0.75))),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              final nonLues = context.watch<NotificationsProvider>().nonLues;
              return _BoutonRond(
                icone: Icons.notifications_outlined,
                badge: nonLues > 0 ? nonLues : null,
                onTap: () => context.push('/notifications'),
              );
            },
          ),
          const SizedBox(width: 10),
          _BoutonRond(icone: Icons.person_outline, onTap: () => context.push('/profil')),
        ],
      ),
    );
  }

  Widget _initialesWidget(String? nom) {
    return Center(
      child: Text(_initiales(nom), style: GoogleFonts.plusJakartaSans(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15)),
    );
  }

  List<Widget> _sectionParent(BuildContext context, dynamic user) {
    final enfants = context.watch<ChildProvider>();

    if (enfants.charge && enfants.enfants.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))];
    }
    if (enfants.enfants.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: EmptyState(
            message: 'Aucun enfant lié',
            sousTitre: 'Contactez l\'école pour activer votre compte parent.',
            icone: Icons.child_care_outlined,
          ),
        ),
      ];
    }

    final dashboard = _dashboard;
    final nbDevoirs = (dashboard?['homeworks_today'] as List? ?? []).length;

    return [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ChildSelector()),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _carteBienvenue(
          nbDevoirs == 0
              ? 'Aujourd\'hui, tout se passe pour le mieux à l\'école.'
              : '$nbDevoirs devoir${nbDevoirs > 1 ? 's' : ''} à préparer pour aujourd\'hui.',
        ),
      ),
      const SizedBox(height: 20),
      if (_chargeDashboard)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
      else if (dashboard != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _carteStat(
                  titre: 'Devoirs du jour',
                  valeur: '$nbDevoirs',
                  icone: Icons.assignment_outlined,
                  couleur: AppColors.purple,
                  onTap: () => context.go('/devoirs'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _carteStat(
                  titre: 'Cours aujourd\'hui',
                  valeur: '${(dashboard['today_timetable'] as List? ?? []).length}',
                  icone: Icons.schedule_outlined,
                  couleur: AppColors.blue,
                  onTap: () => context.push('/calendrier'),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 24),
      _titreSection('Accès rapide'),
      const SizedBox(height: 12),
      _grilleAcces(context, [
        (Icons.assignment_outlined, 'Devoirs', AppColors.purple, () => context.go('/devoirs')),
        (Icons.comment_outlined, 'Comportement', AppColors.blue, () => context.go('/remarques')),
        (Icons.event_busy_outlined, 'Absences', AppColors.orange, () => context.push('/absences')),
        (Icons.bar_chart_outlined, 'Notes', AppColors.green, () => context.go('/notes')),
        (Icons.campaign_outlined, 'Annonces', AppColors.navy, () => context.go('/liaison')),
        (Icons.calendar_today_outlined, 'Calendrier', AppColors.amber, () => context.push('/calendrier')),
        (Icons.forum_outlined, 'Messagerie', AppColors.blue, () => context.push('/messagerie')),
      ]),
    ];
  }

  List<Widget> _sectionPersonnel(BuildContext context, dynamic user) {
    final estAdmin = user?.estAdmin == true;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _carteBienvenue('Prêt(e) pour une nouvelle journée à l\'école ?'),
      ),
      const SizedBox(height: 24),
      _titreSection('Accès rapide'),
      const SizedBox(height: 12),
      _grilleAcces(context, [
        (Icons.groups_outlined, 'Ma classe', AppColors.navy, () => context.go('/teacher/ma-classe')),
        (Icons.assignment_outlined, 'Devoirs', AppColors.purple, () => context.go('/devoirs')),
        (Icons.comment_outlined, 'Comportement', AppColors.blue, () => context.go('/remarques')),
        (Icons.event_busy_outlined, 'Absences', AppColors.orange, () => context.push('/absences')),
        (Icons.campaign_outlined, 'Annonces', AppColors.red, () => context.go('/liaison')),
        (Icons.calendar_today_outlined, 'Calendrier', AppColors.amber, () => context.push('/calendrier')),
        (Icons.forum_outlined, 'Messagerie', AppColors.blue, () => context.push('/messagerie')),
        if (estAdmin) (Icons.admin_panel_settings_outlined, 'Gestion', AppColors.navy, () => context.push('/gestion')),
      ]),
    ];
  }

  Widget _titreSection(String titre) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
      );

  Widget _carteBienvenue(String sousTitre) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.wb_sunny_outlined, color: AppColors.amber),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour !', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
                  const SizedBox(height: 2),
                  Text(sousTitre, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteStat({required String titre, required String valeur, required IconData icone, required Color couleur, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(icone, color: couleur, size: 19),
              ),
              const SizedBox(height: 10),
              Text(valeur, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grilleAcces(BuildContext context, List<(IconData, String, Color, VoidCallback)> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: items.asMap().entries.map((entry) {
          final (icone, titre, couleur, onTap) = entry.value;
          return AnimatedEntry(index: entry.key, child: _CarteAcces(icone: icone, titre: titre, couleur: couleur, onTap: onTap));
        }).toList(),
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final int? badge;
  final VoidCallback onTap;

  const _BoutonRond({required this.icone, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.white.withOpacity(0.16), shape: BoxShape.circle),
        child: Badge(
          isLabelVisible: (badge ?? 0) > 0,
          label: Text('$badge'),
          backgroundColor: AppColors.amber,
          child: Icon(icone, color: AppColors.white, size: 21),
        ),
      ),
    );
  }
}

class _CarteAcces extends StatefulWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteAcces({required this.icone, required this.titre, required this.couleur, required this.onTap});

  @override
  State<_CarteAcces> createState() => _CarteAccesState();
}

class _CarteAccesState extends State<_CarteAcces> {
  double _echelle = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _echelle = 0.96),
      onTapCancel: () => setState(() => _echelle = 1),
      onTapUp: (_) => setState(() => _echelle = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _echelle,
        duration: const Duration(milliseconds: 120),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: widget.couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.icone, color: widget.couleur, size: 21),
                ),
                const SizedBox(height: 8),
                Text(widget.titre, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.body)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
