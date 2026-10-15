/// Un élément du fil d'actualité du parent — annonce, comportement, devoir
/// ou absence réunis en un seul flux chronologique (docs/PRODUCT_ARCHITECTURE.md,
/// voir ChildrenController::feed).
class FilItem {
  final String type; // annonce | comportement | devoir | absence
  final int id;
  final String titre;
  final String? corps;
  final String? photoUrl;
  final String? categorie;
  final String? horodatage;
  final String? auteur;

  const FilItem({
    required this.type,
    required this.id,
    required this.titre,
    this.corps,
    this.photoUrl,
    this.categorie,
    this.horodatage,
    this.auteur,
  });

  factory FilItem.fromJson(Map<String, dynamic> j) => FilItem(
        type:        j['type'] as String,
        id:          j['id'] as int,
        titre:       j['titre'] as String? ?? '',
        corps:       j['corps'] as String?,
        photoUrl:    j['photo_url'] as String?,
        categorie:   j['categorie'] as String?,
        horodatage:  j['horodatage'] as String?,
        auteur:      j['auteur'] as String?,
      );
}
