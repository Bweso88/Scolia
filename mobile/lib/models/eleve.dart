class Eleve {
  final int id;
  final int? classeId;
  final String prenom;
  final String nom;
  final String? matricule;
  final String? photoUrl;
  final String? classeNom;

  const Eleve({
    required this.id,
    this.classeId,
    required this.prenom,
    required this.nom,
    this.matricule,
    this.photoUrl,
    this.classeNom,
  });

  factory Eleve.fromJson(Map<String, dynamic> j) => Eleve(
        id:        j['id'] as int,
        classeId:  j['classe_id'] as int?,
        prenom:    j['prenom'] as String,
        nom:       j['nom'] as String,
        matricule: j['matricule'] as String?,
        photoUrl:  j['photo_url'] as String?,
        classeNom: j['classe_nom'] as String?,
      );

  String get nomComplet => '$prenom $nom';
}
