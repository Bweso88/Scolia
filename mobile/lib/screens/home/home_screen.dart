import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../config/theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (branding?.logoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: branding!.logoUrl!,
                  width: 32, height: 32,
                  errorWidget: (_, __, ___) => const SizedBox(width: 32, height: 32),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(branding?.displayName ?? 'Bonjour, ${user?.name ?? ''}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Bonjour, ${user?.name ?? ''}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.white),
            onPressed: () => context.push('/profil'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.estParent == true) ..._sectionParent(context),
              if (user?.faitPartieDuPersonnel == true) ..._sectionPersonnel(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(indexActuel: 0),
    );
  }

  List<Widget> _sectionParent(BuildContext context) {
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
    return [
      const ChildSelector(),
      const SizedBox(height: 16),
      if (_chargeDashboard)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
      else if (dashboard != null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _carteResume(
            titre: 'Devoirs du jour',
            valeur: '${(dashboard['homeworks_today'] as List? ?? []).length}',
            icone: Icons.assignment_outlined,
            couleur: AppColors.purple,
            onTap: () => context.go('/devoirs'),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _carteResume(
            titre: 'Emploi du temps aujourd\'hui',
            valeur: '${(dashboard['today_timetable'] as List? ?? []).length} cours',
            icone: Icons.schedule_outlined,
            couleur: AppColors.blue,
            onTap: () => context.go('/calendrier'),
          ),
        ),
      ],
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Accès rapide', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _CarteAcces(icone: Icons.assignment_outlined,              titre: 'Devoirs',     couleur: AppColors.purple, onTap: () => context.go('/devoirs')),
            _CarteAcces(icone: Icons.comment_outlined,                 titre: 'Comportement', couleur: AppColors.blue,   onTap: () => context.go('/remarques')),
            _CarteAcces(icone: Icons.event_busy_outlined,              titre: 'Absences',     couleur: AppColors.orange, onTap: () => context.go('/absences')),
            _CarteAcces(icone: Icons.bar_chart_outlined,               titre: 'Notes',        couleur: AppColors.green,  onTap: () => context.go('/notes')),
            _CarteAcces(icone: Icons.campaign_outlined,                titre: 'Annonces',     couleur: AppColors.navy,   onTap: () => context.go('/liaison')),
            _CarteAcces(icone: Icons.calendar_today_outlined,          titre: 'Calendrier',   couleur: AppColors.amber,  onTap: () => context.go('/calendrier')),
          ],
        ),
      ),
    ];
  }

  List<Widget> _sectionPersonnel(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Accès rapide', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _CarteAcces(icone: Icons.groups_outlined,         titre: 'Ma classe',     couleur: AppColors.navy,   onTap: () => context.go('/teacher/ma-classe')),
            _CarteAcces(icone: Icons.assignment_outlined,     titre: 'Devoirs',       couleur: AppColors.purple, onTap: () => context.go('/devoirs')),
            _CarteAcces(icone: Icons.comment_outlined,        titre: 'Comportement',  couleur: AppColors.blue,   onTap: () => context.go('/remarques')),
            _CarteAcces(icone: Icons.event_busy_outlined,     titre: 'Absences',      couleur: AppColors.orange, onTap: () => context.go('/absences')),
            _CarteAcces(icone: Icons.campaign_outlined,       titre: 'Annonces',      couleur: AppColors.red,    onTap: () => context.go('/liaison')),
            _CarteAcces(icone: Icons.calendar_today_outlined, titre: 'Calendrier',    couleur: AppColors.amber,  onTap: () => context.go('/calendrier')),
          ],
        ),
      ),
    ];
  }

  Widget _carteResume({required String titre, required String valeur, required IconData icone, required Color couleur, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: couleur, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted)),
                    Text(valeur, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.navy)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarteAcces extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final VoidCallback onTap;

  const _CarteAcces({required this.icone, required this.titre, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: couleur, size: 28),
              const SizedBox(height: 8),
              Text(titre, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.body)),
            ],
          ),
        ),
      ),
    );
  }
}
