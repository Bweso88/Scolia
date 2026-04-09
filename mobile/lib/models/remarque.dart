class Remarque {
  final int id;
  final String categorie;
  final String priorite;
  final String message;
  final String? elevePrenom;
  final String? eleveNom;
  final String? auteurPrenom;
  final String? auteurNom;
  final String createdAt;

  const Remarque({
    required this.id,
    required this.categorie,
    required this.priorite,
    required this.message,
    this.elevePrenom,
    this.eleveNom,
    this.auteurPrenom,
    this.auteurNom,
    required this.createdAt,
  });

  factory Remarque.fromJson(Map<String, dynamic> j) => Remarque(
        id:           j['id'] as int,
        categorie:    j['categorie'] as String? ?? 'autre',
        priorite:     j['priorite'] as String? ?? 'info',
        message:      j['message'] as String,
        elevePrenom:  j['eleve_prenom'] as String?,
        eleveNom:     j['eleve_nom'] as String?,
        auteurPrenom: j['auteur_prenom'] as String?,
        auteurNom:    j['auteur_nom'] as String?,
        createdAt:    j['created_at'] as String,
      );
}
