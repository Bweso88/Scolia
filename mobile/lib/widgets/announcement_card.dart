import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';
import '../config/theme.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  static const _couleurs = {
    'info':     AppColors.blue,
    'reunion':  AppColors.purple,
    'sortie':   AppColors.green,
    'examen':   AppColors.red,
    'vacances': AppColors.amber,
    'urgence':  AppColors.red,
  };

  static const _icones = {
    'info':     Icons.info_outline,
    'reunion':  Icons.groups_outlined,
    'sortie':   Icons.directions_walk_outlined,
    'examen':   Icons.edit_note_outlined,
    'vacances': Icons.beach_access_outlined,
    'urgence':  Icons.priority_high,
  };

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurs[announcement.category] ?? AppColors.muted;
    final icone   = _icones[announcement.category]   ?? Icons.campaign_outlined;

    DateTime? date;
    try { if (announcement.publishedAt != null) date = DateTime.parse(announcement.publishedAt!); } catch (_) {}

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
                  Text(
                    announcement.title,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    announcement.body,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (announcement.authorName != null) ...[
                        Text(announcement.authorName!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(width: 6),
                      ],
                      if (date != null)
                        Text(DateFormat('d MMM', 'fr_FR').format(date), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                    ],
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
