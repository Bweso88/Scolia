import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/remarque.dart';
import '../config/theme.dart';

class RemarqueCard extends StatelessWidget {
  final Remarque remarque;

  const RemarqueCard({super.key, required this.remarque});

  static const _couleursPriorite = {
    'info':         AppColors.blue,
    'avertissement': AppColors.orange,
    'urgent':       AppColors.red,
  };

  static const _iconesCat = {
    'felicitation':  Icons.star_outline,
    'comportement':  Icons.warning_amber_outlined,
    'absence':       Icons.person_off_outlined,
    'retard':        Icons.schedule_outlined,
    'sante':         Icons.medical_services_outlined,
    'autre':         Icons.comment_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final couleur = _couleursPriorite[remarque.priorite] ?? AppColors.muted;
    final icone   = _iconesCat[remarque.categorie] ?? Icons.comment_outlined;

    DateTime? date;
    try { date = DateTime.parse(remarque.createdAt); } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remarque.elevePrenom != null)
                    Text(
                      '${remarque.elevePrenom} ${remarque.eleveNom}',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    remarque.message,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date != null ? DateFormat('d MMMM yyyy', 'fr_FR').format(date) : '',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                remarque.priorite,
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: couleur, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
