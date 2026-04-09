class Evenement {
  final int id;
  final String titre;
  final String? description;
  final String dateDebut;
  final String? heureDebut;
  final String? lieu;
  final String type;
  final String? auteurNom;

  const Evenement({
    required this.id,
    required this.titre,
    this.description,
    required this.dateDebut,
    this.heureDebut,
    this.lieu,
    required this.type,
    this.auteurNom,
  });

  factory Evenement.fromJson(Map<String, dynamic> j) => Evenement(
        id:          j['id'] as int,
        titre:       j['titre'] as String,
        description: j['description'] as String?,
        dateDebut:   j['date_debut'] as String,
        heureDebut:  j['heure_debut'] as String?,
        lieu:        j['lieu'] as String?,
        type:        j['type'] as String? ?? 'autre',
        auteurNom:   '${j['auteur_prenom'] ?? ''} ${j['auteur_nom'] ?? ''}'.trim(),
      );
}
