import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/announcement.dart';
import '../config/theme.dart';
import 'pill_badge.dart';

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

  static const _libelles = {
    'info':     'Information',
    'reunion':  'Réunion',
    'sortie':   'Sortie',
    'examen':   'Examen',
    'vacances': 'Vacances',
    'urgence':  'Message urgent',
  };

  @override
  Widget build(BuildContext context) {
    final estUrgent = announcement.category == 'urgence';
    final couleur = _couleurs[announcement.category] ?? AppColors.muted;
    final icone   = _icones[announcement.category]   ?? Icons.campaign_outlined;

    DateTime? date;
    try { if (announcement.publishedAt != null) date = DateTime.parse(announcement.publishedAt!); } catch (_) {}
    final dateTexte = date != null ? 'Publié ${DateFormat('d MMM', 'fr_FR').format(date)}' : null;

    if (estUrgent) {
      return Card(
        color: AppColors.navy,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: AppColors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text('MESSAGE URGENT', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amber, letterSpacing: 0.6)),
                ],
              ),
              const SizedBox(height: 10),
              Text(announcement.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.white)),
              const SizedBox(height: 6),
              Text(announcement.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.white.withOpacity(0.85)), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (dateTexte != null)
                    Text(dateTexte, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.white.withOpacity(0.6))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(30)),
                    child: Text('Lire plus', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: couleur.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
              child: Icon(icone, color: couleur, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(announcement.title,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      PillBadge(label: (_libelles[announcement.category] ?? announcement.category).toUpperCase(), couleur: couleur),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(announcement.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.body), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (announcement.authorName != null) ...[
                        Text(announcement.authorName!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(width: 6),
                        const Text('·', style: TextStyle(color: AppColors.muted)),
                        const SizedBox(width: 6),
                      ],
                      if (dateTexte != null)
                        Text(dateTexte, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
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
