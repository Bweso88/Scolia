/// Une matière, telle que renvoyée par SubjectResource. Donnée de
/// référence simple : plus de coefficient ni de classe associée dans le
/// nouveau schéma (le coefficient est désormais porté par chaque note).
class Matiere {
  final int id;
  final String nom;

  const Matiere({required this.id, required this.nom});

  factory Matiere.fromJson(Map<String, dynamic> j) => Matiere(
        id:  j['id'] as int,
        nom: j['name'] as String,
      );
}
