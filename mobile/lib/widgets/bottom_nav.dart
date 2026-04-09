import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class BottomNav extends StatelessWidget {
  final int indexActuel;

  const BottomNav({super.key, required this.indexActuel});

  static const _items = [
    (icone: Icons.home_outlined,         label: 'Accueil',      route: '/accueil'),
    (icone: Icons.menu_book_outlined,    label: 'Liaison',      route: '/liaison'),
    (icone: Icons.comment_outlined,      label: 'Remarques',    route: '/remarques'),
    (icone: Icons.bar_chart_outlined,    label: 'Notes',        route: '/notes'),
    (icone: Icons.account_balance_wallet_outlined, label: 'Frais', route: '/frais'),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: indexActuel,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.navy.withOpacity(0.1),
      onDestinationSelected: (i) {
        if (i != indexActuel) context.go(_items[i].route);
      },
      destinations: _items.map((item) => NavigationDestination(
        icon:          Icon(item.icone,     color: AppColors.muted),
        selectedIcon:  Icon(item.icone,     color: AppColors.navy),
        label:         item.label,
      )).toList(),
    );
  }
}
