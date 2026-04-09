class Periode {
  final int id;
  final String nom;
  final String? dateDebut;
  final String? dateFin;
  final String? anneeScolaire;

  const Periode({
    required this.id,
    required this.nom,
    this.dateDebut,
    this.dateFin,
    this.anneeScolaire,
  });

  factory Periode.fromJson(Map<String, dynamic> j) => Periode(
        id:            j['id'] as int,
        nom:           j['nom'] as String,
        dateDebut:     j['date_debut'] as String?,
        dateFin:       j['date_fin'] as String?,
        anneeScolaire: j['annee_scolaire'] as String?,
      );
}
