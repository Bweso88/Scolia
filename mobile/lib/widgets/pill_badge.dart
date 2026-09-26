import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badge coloré arrondi (catégorie, statut, "Urgent"...), pour remplacer
/// les petits Container ad-hoc dispersés dans les cartes.
class PillBadge extends StatelessWidget {
  final String label;
  final Color couleur;
  final IconData? icone;

  const PillBadge({super.key, required this.label, required this.couleur, this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: couleur),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: couleur, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
