import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/frais_scolarite.dart';
import '../config/theme.dart';
import 'frais_status_badge.dart';

class FraisRow extends StatelessWidget {
  final FraisScolarite frais;

  const FraisRow({super.key, required this.frais});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'fr_FR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Indicateur couleur à gauche
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: frais.couleurStatut,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Nom du mois
          SizedBox(
            width: 90,
            child: Text(
              frais.moisNom,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.navy,
              ),
            ),
          ),

          // Montants
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmt.format(frais.montantDu)} FCFA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.body,
                  ),
                ),
                if (frais.statut == 'partiel')
                  Text(
                    'Payé : ${fmt.format(frais.montantPaye)} FCFA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.orange,
                    ),
                  ),
                if (frais.datePaiement != null && frais.statut == 'paye')
                  Text(
                    frais.datePaiement!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),

          // Badge statut
          FraisStatusBadge(statut: frais.statut),
        ],
      ),
    );
  }
}
