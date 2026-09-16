import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/remarque.dart';
import '../config/theme.dart';

class RemarqueCard extends StatelessWidget {
  final Remarque remarque;

  const RemarqueCard({super.key, required this.remarque});

  static const _couleurs = {
    'positive':       AppColors.green,
    'discipline':     AppColors.orange,
    'incident':       AppColors.red,
    'participation':  AppColors.blue,
    'note_generale':  AppColors.muted,
  };

  static const _icones = {
    'positive':       Icons.star_outline,
    'discipline':     Icons.warning_amber_outlined,
    'incident':       Icons.report_outlined,
    'participation':  Icons.forum_outlined,
    'note_generale':  Icons.comment_outlined,
  };

  static const _libelles = {
    'positive':       'Positif',
    'discipline':     'Discipline',
    'incident':       'Incident',
    'participation':  'Participation',
    'note_generale':  'Observation',
  };

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurs[remarque.category] ?? AppColors.muted;
    final icone   = _icones[remarque.category] ?? Icons.comment_outlined;

    DateTime? date;
    try { if (remarque.occurredAt != null) date = DateTime.parse(remarque.occurredAt!); } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(remarque.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy)),
                  if (remarque.description != null && remarque.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(remarque.description!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (date != null)
                        Text(DateFormat('d MMMM yyyy', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                      if (remarque.authorName != null) ...[
                        const SizedBox(width: 6),
                        Text('· ${remarque.authorName}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(_libelles[remarque.category] ?? remarque.category,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: couleur, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
