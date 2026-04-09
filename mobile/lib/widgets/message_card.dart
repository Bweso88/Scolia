import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_liaison.dart';
import '../config/theme.dart';

class MessageCard extends StatelessWidget {
  final MessageLiaison message;
  final VoidCallback? onTap;

  const MessageCard({super.key, required this.message, this.onTap});

  static const _couleurs = {
    'info':          AppColors.blue,
    'devoir':        AppColors.purple,
    'autorisation':  AppColors.orange,
    'retard':        AppColors.red,
    'autre':         AppColors.muted,
  };

  static const _icones = {
    'info':         Icons.info_outline,
    'devoir':       Icons.assignment_outlined,
    'autorisation': Icons.assignment_turned_in_outlined,
    'retard':       Icons.schedule_outlined,
    'autre':        Icons.article_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final couleur = _couleurs[message.categorie] ?? AppColors.muted;
    final icone   = _icones[message.categorie]   ?? Icons.article_outlined;

    DateTime? date;
    try { date = DateTime.parse(message.createdAt); } catch (_) {}

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    if (message.titre != null)
                      Text(
                        message.titre!,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      message.contenu,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.body,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (message.classeNom != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(message.classeNom!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          date != null ? DateFormat('d MMM', 'fr_FR').format(date) : '',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.muted),
                        ),
                        if (message.necessite_ack) ...[
                          const SizedBox(width: 6),
                          Icon(
                            message.accuse_reception == true ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 14,
                            color: message.accuse_reception == true ? AppColors.green : AppColors.orange,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
