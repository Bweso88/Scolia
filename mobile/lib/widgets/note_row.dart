import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../config/theme.dart';

class NoteRow extends StatelessWidget {
  final NoteMatiere noteMatiere;

  const NoteRow({super.key, required this.noteMatiere});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Nom de la matière + coefficient
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noteMatiere.matiereNom,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.body,
                  ),
                ),
                Text(
                  'Coeff. ${noteMatiere.coefficient.toStringAsFixed(1)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Note / Sur
          Expanded(
            flex: 2,
            child: noteMatiere.aUneNote
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${noteMatiere.note!.toStringAsFixed(1)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: noteMatiere.couleur,
                        ),
                      ),
                      Text(
                        '/ ${noteMatiere.noteSur!.toStringAsFixed(0)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '—',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.muted,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),

          // Barre de progression
          Expanded(
            flex: 3,
            child: noteMatiere.aUneNote
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: noteMatiere.pourcentage.clamp(0.0, 1.0),
                          backgroundColor: AppColors.light,
                          valueColor: AlwaysStoppedAnimation(noteMatiere.couleur),
                          minHeight: 6,
                        ),
                      ),
                      if (noteMatiere.commentaire != null &&
                          noteMatiere.commentaire!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          noteMatiere.commentaire!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.muted,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
