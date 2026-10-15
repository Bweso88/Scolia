import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

/// Hub de gestion de l'établissement, réservé à la direction
/// (école/school_admin) — équivalent mobile du panel web Filament
/// (docs/PRODUCT_ARCHITECTURE.md §15).
class GestionScreen extends StatelessWidget {
  const GestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion de l\'école')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _Carte(icone: Icons.class_outlined, titre: 'Classes', couleur: AppColors.navy, onTap: () => context.push('/gestion/classes')),
            _Carte(icone: Icons.people_outline, titre: 'Élèves', couleur: AppColors.purple, onTap: () => context.push('/gestion/eleves')),
            _Carte(icone: Icons.school_outlined, titre: 'Professeurs', couleur: AppColors.blue, onTap: () => context.push('/gestion/professeurs')),
            _Carte(icone: Icons.menu_book_outlined, titre: 'Matières', couleur: AppColors.green, onTap: () => context.push('/gestion/matieres')),
          ],
        ),
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final VoidCallback onTap;

  const _Carte({required this.icone, required this.titre, required this.couleur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: couleur, size: 32),
            const SizedBox(height: 10),
            Text(titre, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
