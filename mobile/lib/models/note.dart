import 'package:flutter/material.dart';
import '../config/theme.dart';

class Note {
  final int id;
  final double note;
  final double noteSur;
  final String? commentaire;
  final String typeEvaluation;
  final String? dateEvaluation;
  final String? matiereNom;
  final double? coefficient;
  final String? periodeNom;
  final String? elevePrenom;
  final String? eleveNom;

  const Note({
    required this.id,
    required this.note,
    required this.noteSur,
    this.commentaire,
    required this.typeEvaluation,
    this.dateEvaluation,
    this.matiereNom,
    this.coefficient,
    this.periodeNom,
    this.elevePrenom,
    this.eleveNom,
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id:             j['id'] as int,
        note:           double.tryParse(j['note'].toString()) ?? 0,
        noteSur:        double.tryParse(j['note_sur'].toString()) ?? 20,
        commentaire:    j['commentaire'] as String?,
        typeEvaluation: j['type_evaluation'] as String? ?? 'controle',
        dateEvaluation: j['date_evaluation'] as String?,
        matiereNom:     j['matiere_nom'] as String?,
        coefficient:    double.tryParse(j['coefficient']?.toString() ?? '1'),
        periodeNom:     j['periode_nom'] as String?,
        elevePrenom:    j['eleve_prenom'] as String?,
        eleveNom:       j['eleve_nom'] as String?,
      );

  double get pourcentage => noteSur > 0 ? note / noteSur : 0;

  Color get couleur {
    if (pourcentage >= 0.70) return AppColors.green;
    if (pourcentage >= 0.50) return AppColors.orange;
    return AppColors.red;
  }

  String get affichage => '${note.toStringAsFixed(1)}/${noteSur.toStringAsFixed(0)}';
}

class NoteMatiere {
  final int matiereId;
  final String matiereNom;
  final double coefficient;
  final int? noteId;
  final double? note;
  final double? noteSur;
  final String? commentaire;
  final String? typeEvaluation;
  final String? dateEvaluation;

  const NoteMatiere({
    required this.matiereId,
    required this.matiereNom,
    required this.coefficient,
    this.noteId,
    this.note,
    this.noteSur,
    this.commentaire,
    this.typeEvaluation,
    this.dateEvaluation,
  });

  factory NoteMatiere.fromJson(Map<String, dynamic> j) => NoteMatiere(
        matiereId:      j['matiere_id'] as int,
        matiereNom:     j['matiere_nom'] as String,
        coefficient:    double.tryParse(j['coefficient'].toString()) ?? 1.0,
        noteId:         j['note_id'] as int?,
        note:           j['note'] != null ? double.tryParse(j['note'].toString()) : null,
        noteSur:        j['note_sur'] != null ? double.tryParse(j['note_sur'].toString()) : null,
        commentaire:    j['commentaire'] as String?,
        typeEvaluation: j['type_evaluation'] as String?,
        dateEvaluation: j['date_evaluation'] as String?,
      );

  bool get aUneNote => note != null;

  double get pourcentage => (note != null && noteSur != null && noteSur! > 0) ? note! / noteSur! : 0;

  Color get couleur {
    if (!aUneNote) return AppColors.muted;
    if (pourcentage >= 0.70) return AppColors.green;
    if (pourcentage >= 0.50) return AppColors.orange;
    return AppColors.red;
  }
}
