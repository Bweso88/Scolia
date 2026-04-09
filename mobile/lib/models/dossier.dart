class Dossier {
  final int id;
  final int eleveId;
  final String prenom;
  final String nom;
  final String? photoUrl;
  final String? classeNom;
  final bool actif;
  final String? dateExpiration;

  const Dossier({
    required this.id,
    required this.eleveId,
    required this.prenom,
    required this.nom,
    this.photoUrl,
    this.classeNom,
    required this.actif,
    this.dateExpiration,
  });

  factory Dossier.fromJson(Map<String, dynamic> j) => Dossier(
        id:             j['id'] as int,
        eleveId:        j['eleve_id'] as int,
        prenom:         j['prenom'] as String,
        nom:            j['nom'] as String,
        photoUrl:       j['photo_url'] as String?,
        classeNom:      j['classe_nom'] as String?,
        actif:          j['actif'] == true || j['actif'] == 1,
        dateExpiration: j['date_expiration'] as String?,
      );

  String get nomComplet => '$prenom $nom';
}
