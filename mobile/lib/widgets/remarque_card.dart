import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/remarque.dart';
import '../config/theme.dart';
import 'pill_badge.dart';

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
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: couleur),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: couleur.withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(icone, color: couleur, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (remarque.authorName != null)
                                Text(remarque.authorName!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.navy)),
                              if (date != null)
                                Text(DateFormat('d MMMM yyyy', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        PillBadge(label: (_libelles[remarque.category] ?? remarque.category).toUpperCase(), couleur: couleur),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(remarque.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
                    if (remarque.description != null && remarque.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(remarque.description!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
