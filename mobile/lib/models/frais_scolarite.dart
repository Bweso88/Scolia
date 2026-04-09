import 'package:flutter/material.dart';
import '../config/theme.dart';

class FraisScolarite {
  final int id;
  final int mois;
  final String anneeScolaire;
  final double montantDu;
  final double montantPaye;
  final String statut;
  final String? datePaiement;
  final String? noteAdmin;
  final String? elevePrenom;
  final String? eleveNom;

  const FraisScolarite({
    required this.id,
    required this.mois,
    required this.anneeScolaire,
    required this.montantDu,
    required this.montantPaye,
    required this.statut,
    this.datePaiement,
    this.noteAdmin,
    this.elevePrenom,
    this.eleveNom,
  });

  factory FraisScolarite.fromJson(Map<String, dynamic> j) => FraisScolarite(
        id:            j['id'] as int,
        mois:          j['mois'] as int,
        anneeScolaire: j['annee_scolaire'] as String,
        montantDu:     double.tryParse(j['montant_du'].toString()) ?? 0,
        montantPaye:   double.tryParse(j['montant_paye'].toString()) ?? 0,
        statut:        j['statut'] as String? ?? 'non_paye',
        datePaiement:  j['date_paiement'] as String?,
        noteAdmin:     j['note_admin'] as String?,
        elevePrenom:   j['eleve_prenom'] as String?,
        eleveNom:      j['eleve_nom'] as String?,
      );

  static const _moisNoms = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  String get moisNom => mois >= 1 && mois <= 12 ? _moisNoms[mois] : 'Mois $mois';

  Color get couleurStatut {
    switch (statut) {
      case 'paye':     return AppColors.green;
      case 'partiel':  return AppColors.orange;
      default:         return AppColors.red;
    }
  }

  String get libelleStatut {
    switch (statut) {
      case 'paye':     return 'Payé';
      case 'partiel':  return 'Partiel';
      default:         return 'Non payé';
    }
  }
}

class ResumeFrais {
  final double totalDu;
  final double totalPaye;
  final double solde;
  final int nbMois;
  final int nbPayes;
  final int nbPartiels;
  final int nbImpayes;

  const ResumeFrais({
    required this.totalDu,
    required this.totalPaye,
    required this.solde,
    required this.nbMois,
    required this.nbPayes,
    required this.nbPartiels,
    required this.nbImpayes,
  });

  factory ResumeFrais.fromJson(Map<String, dynamic> j) => ResumeFrais(
        totalDu:     double.tryParse(j['total_du']?.toString() ?? '0') ?? 0,
        totalPaye:   double.tryParse(j['total_paye']?.toString() ?? '0') ?? 0,
        solde:       double.tryParse(j['solde']?.toString() ?? '0') ?? 0,
        nbMois:      int.tryParse(j['nb_mois']?.toString() ?? '0') ?? 0,
        nbPayes:     int.tryParse(j['nb_payes']?.toString() ?? '0') ?? 0,
        nbPartiels:  int.tryParse(j['nb_partiels']?.toString() ?? '0') ?? 0,
        nbImpayes:   int.tryParse(j['nb_impayes']?.toString() ?? '0') ?? 0,
      );

  double get tauxPaiement => totalDu > 0 ? totalPaye / totalDu : 0;
  bool get toutPaye => solde <= 0;
}
