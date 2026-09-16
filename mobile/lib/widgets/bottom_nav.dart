import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

/// Les 4 premiers onglets (Accueil, Devoirs, Comportement, Annonces) sont
/// communs aux deux profils, pour que `indexActuel` reste cohérent partout
/// dans l'application ; seul le 5e diffère (Notes pour un parent, Ma
/// classe pour l'enseignant) — docs/PRODUCT_ARCHITECTURE.md §10.
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

    return NavigationBar(
      selectedIndex: indexActuel,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.navy.withOpacity(0.1),
      onDestinationSelected: (i) {
        if (i != indexActuel) context.go(items[i].route);
      },
      destinations: items.map((item) => NavigationDestination(
        icon:         Icon(item.icone, color: AppColors.muted),
        selectedIcon: Icon(item.icone, color: AppColors.navy),
        label:        item.label,
      )).toList(),
    );
  }
}
