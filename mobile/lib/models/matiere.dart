class Matiere {
  final int id;
  final String nom;
  final double coefficient;
  final int? classeId;
  final String? classeNom;

  const Matiere({
    required this.id,
    required this.nom,
    required this.coefficient,
    this.classeId,
    this.classeNom,
  });

  factory Matiere.fromJson(Map<String, dynamic> j) => Matiere(
        id:          j['id'] as int,
        nom:         j['nom'] as String,
        coefficient: double.tryParse(j['coefficient'].toString()) ?? 1.0,
        classeId:    j['classe_id'] as int?,
        classeNom:   j['classe_nom'] as String?,
      );
}
