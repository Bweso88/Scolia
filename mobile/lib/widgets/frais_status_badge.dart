import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class FraisStatusBadge extends StatelessWidget {
  final String statut;

  const FraisStatusBadge({super.key, required this.statut});

  @override
  Widget build(BuildContext context) {
    final Color couleur;
    final String libelle;
    final IconData icone;

    switch (statut) {
      case 'paye':
        couleur = AppColors.green; libelle = 'Payé'; icone = Icons.check_circle_outline;
      case 'partiel':
        couleur = AppColors.orange; libelle = 'Partiel'; icone = Icons.timelapse_outlined;
      default:
        couleur = AppColors.red; libelle = 'Non payé'; icone = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: couleur),
          const SizedBox(width: 4),
          Text(
            libelle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}
