import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

/// Les 4 premiers onglets (Accueil, Devoirs, Comportement, Annonces) sont
/// communs aux deux profils, pour que `indexActuel` reste cohérent partout
/// dans l'application ; seul le 5e diffère (Notes pour un parent, Ma
/// classe pour l'enseignant) — docs/PRODUCT_ARCHITECTURE.md §10.
///
/// Barre flottante arrondie (plutôt que la NavigationBar Material bord à
/// bord) : l'onglet actif bascule sur un fond coloré avec une légère
/// animation, pour un rendu moins statique.
class BottomNav extends StatelessWidget {
  final int indexActuel;

  const BottomNav({super.key, required this.indexActuel});

  static const _itemsParent = [
    (icone: Icons.home_outlined,          label: 'Accueil',    route: '/accueil'),
    (icone: Icons.assignment_outlined,    label: 'Devoirs',    route: '/devoirs'),
    (icone: Icons.comment_outlined,       label: 'Comport.',   route: '/remarques'),
    (icone: Icons.campaign_outlined,      label: 'Annonces',   route: '/liaison'),
    (icone: Icons.bar_chart_outlined,     label: 'Notes',      route: '/notes'),
  ];

  static const _itemsPersonnel = [
    (icone: Icons.home_outlined,          label: 'Accueil',    route: '/accueil'),
    (icone: Icons.assignment_outlined,    label: 'Devoirs',    route: '/devoirs'),
    (icone: Icons.comment_outlined,       label: 'Comport.',   route: '/remarques'),
    (icone: Icons.campaign_outlined,      label: 'Annonces',   route: '/liaison'),
    (icone: Icons.groups_outlined,        label: 'Ma classe',  route: '/teacher/ma-classe'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final items = user?.faitPartieDuPersonnel == true ? _itemsPersonnel : _itemsParent;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final actif = i == indexActuel;
            return _Onglet(
              icone: item.icone,
              label: item.label,
              actif: actif,
              onTap: () {
                if (!actif) context.go(item.route);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Onglet extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool actif;
  final VoidCallback onTap;

  const _Onglet({required this.icone, required this.label, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: actif ? AppColors.navy.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: actif ? AppColors.navy : AppColors.muted, size: 22),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                  color: actif ? AppColors.navy : AppColors.muted,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
