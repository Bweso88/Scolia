import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class BottomNav extends StatelessWidget {
  final int indexActuel;

  const BottomNav({super.key, required this.indexActuel});

  static const _itemsParent = [
    (icone: Icons.home_outlined,                     label: 'Accueil',    route: '/accueil'),
    (icone: Icons.menu_book_outlined,               label: 'Liaison',    route: '/liaison'),
    (icone: Icons.comment_outlined,                 label: 'Remarques',  route: '/remarques'),
    (icone: Icons.bar_chart_outlined,               label: 'Notes',      route: '/notes'),
    (icone: Icons.account_balance_wallet_outlined,  label: 'Frais',      route: '/frais'),
  ];

  static const _itemsEnseignant = [
    (icone: Icons.home_outlined,          label: 'Accueil',    route: '/accueil'),
    (icone: Icons.groups_outlined,        label: 'Ma classe',  route: '/teacher/ma-classe'),
    (icone: Icons.menu_book_outlined,     label: 'Liaison',    route: '/liaison'),
    (icone: Icons.comment_outlined,       label: 'Remarques',  route: '/remarques'),
    (icone: Icons.calendar_today_outlined,label: 'Calendrier', route: '/calendrier'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final items = user?.estEnseignant == true ? _itemsEnseignant : _itemsParent;

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
