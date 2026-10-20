import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

/// Les mêmes 5 onglets pour tout le monde, parent comme personnel —
/// repris du design fourni par l'utilisateur. "Ma classe" (personnel) et
/// "Notes" (parent) restent accessibles depuis l'accueil plutôt que dans
/// cette barre (docs/PRODUCT_ARCHITECTURE.md §10).
///
/// Barre flottante en verre dépoli (reprise du mockup "Scholarly") :
/// l'onglet actif bascule sur un fond bleu clair avec un petit repère au-
/// dessus, pour un rendu moins statique que la NavigationBar Material.
class BottomNav extends StatelessWidget {
  final int indexActuel;

  const BottomNav({super.key, required this.indexActuel});

  static const _items = [
    (icone: Icons.home_outlined,            iconeActif: Icons.home_rounded,            label: 'Accueil',  route: '/accueil'),
    (icone: Icons.menu_book_outlined,       iconeActif: Icons.menu_book_rounded,       label: 'Devoirs',  route: '/devoirs'),
    (icone: Icons.favorite_outline_rounded, iconeActif: Icons.favorite_rounded,        label: 'Suivi',    route: '/remarques'),
    (icone: Icons.chat_bubble_outline_rounded, iconeActif: Icons.chat_bubble_rounded,  label: 'Messages', route: '/messagerie'),
    (icone: Icons.calendar_today_outlined,  iconeActif: Icons.calendar_today_rounded,  label: 'Agenda',   route: '/agenda'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.white),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final actif = i == indexActuel;
                return _Onglet(
                  icone: actif ? item.iconeActif : item.icone,
                  label: item.label,
                  actif: actif,
                  onTap: () {
                    if (!actif) context.go(item.route);
                  },
                );
              }).toList(),
            ),
          ),
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
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            if (actif)
              Positioned(
                top: 2,
                child: Container(width: 22, height: 3, decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(2))),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: actif ? AppColors.blue.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icone, color: actif ? AppColors.blue : AppColors.muted, size: 22),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                      color: actif ? AppColors.blue : AppColors.muted,
                    ),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
