/// Une année scolaire, telle que renvoyée par SchoolYearResource — donnée
/// de référence, créée hors MVP (docs backend), simplement listée ici pour
/// choisir dans quelle année scolaire rattacher une nouvelle période de
/// notation.
class AnneeScolaire {
  final int id;
  final String label;
  final bool estEnCours;

  const AnneeScolaire({required this.id, required this.label, required this.estEnCours});

  factory AnneeScolaire.fromJson(Map<String, dynamic> j) => AnneeScolaire(
        id:          j['id'] as int,
        label:       j['label'] as String,
        estEnCours:  j['is_current'] as bool? ?? false,
      );
}
