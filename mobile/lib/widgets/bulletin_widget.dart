import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/note.dart';
import '../config/theme.dart';

class BulletinWidget extends StatelessWidget {
  final List<NoteMatiere> notesMatieres;
  final double? moyenneGenerale;

  const BulletinWidget({
    super.key,
    required this.notesMatieres,
    this.moyenneGenerale,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...notesMatieres.map((nm) => _LigneMatiere(nm: nm)),
          if (moyenneGenerale != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moyenne générale',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _couleurMoyenne(moyenneGenerale!).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${moyenneGenerale!.toStringAsFixed(2)}/20',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _couleurMoyenne(moyenneGenerale!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _couleurMoyenne(double moy) {
    if (moy >= 14) return AppColors.green;
    if (moy >= 10) return AppColors.orange;
    return AppColors.red;
  }
}

class _LigneMatiere extends StatelessWidget {
  final NoteMatiere nm;

  const _LigneMatiere({required this.nm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nm.matiereNom,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.body,
                      ),
                    ),
                    Text(
                      'Coeff. ${nm.coefficient.toStringAsFixed(1)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (nm.aUneNote)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: nm.couleur.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${nm.note!.toStringAsFixed(1)}/${nm.noteSur!.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: nm.couleur,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Text('—', style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
            ],
          ),
          if (nm.aUneNote) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: nm.pourcentage,
                backgroundColor: AppColors.light,
                valueColor: AlwaysStoppedAnimation(nm.couleur),
                minHeight: 5,
              ),
            ),
            if (nm.commentaire != null && nm.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                nm.commentaire!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
          const Divider(height: 16, thickness: 0.5),
        ],
      ),
    );
  }
}
