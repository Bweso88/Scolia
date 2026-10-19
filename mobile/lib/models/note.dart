import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Une note, telle que renvoyée par GradeResource. Le "bulletin" agrégé
/// (moyenne par matière, classement) reste un chantier V2
/// (docs/PRODUCT_ARCHITECTURE.md §4) : cet écran calcule une moyenne
/// pondérée simple côté client à partir des notes reçues.
class Note {
  final int id;
  final String? matiereNom;
  final String? periodeNom;
  final String type;
  final double score;
  final double maxScore;
  final double coefficient;
  final String? commentaire;

  const Note({
    required this.id,
    this.matiereNom,
    this.periodeNom,
    this.type = 'devoir',
    required this.score,
    required this.maxScore,
    required this.coefficient,
    this.commentaire,
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id:          j['id'] as int,
        matiereNom:  j['subject'] as String?,
        periodeNom:  j['grading_period'] as String?,
        type:        j['type'] as String? ?? 'devoir',
        score:       double.tryParse(j['score'].toString()) ?? 0,
        maxScore:    double.tryParse(j['max_score'].toString()) ?? 20,
        coefficient: double.tryParse(j['coefficient'].toString()) ?? 1,
        commentaire: j['comment'] as String?,
      );

  double get pourcentage => maxScore > 0 ? score / maxScore : 0;
  String get affichage => '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(0)}';

  Color get couleur {
    if (pourcentage >= 0.70) return AppColors.green;
    if (pourcentage >= 0.50) return AppColors.orange;
    return AppColors.red;
  }
}

/// Types d'évaluation — une classification générale qui s'applique à
/// n'importe quelle école, indépendamment de son propre barème (laissé à
/// la saisie libre du coefficient sur chaque note).
const typesNote = {
  'interrogation': 'Interrogation',
  'devoir':        'Devoir sur table',
  'partiel':       'Partiel',
  'composition':   'Composition',
  'examen':        'Examen',
};

/// Moyenne pondérée (Σ note/20 × coefficient ÷ Σ coefficient), calculée
/// côté client à partir d'une liste de [Note] ramenées sur 20.
double? moyennePonderee(List<Note> notes) {
  if (notes.isEmpty) return null;
  final totalCoeff = notes.fold<double>(0, (s, n) => s + n.coefficient);
  if (totalCoeff == 0) return null;
  final totalPondere = notes.fold<double>(0, (s, n) => s + (n.score / n.maxScore * 20) * n.coefficient);
  return totalPondere / totalCoeff;
}
