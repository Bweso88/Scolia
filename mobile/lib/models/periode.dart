/// Une période de notation, telle que renvoyée par GradingPeriodResource.
class Periode {
  final int id;
  final String nom;
  final int schoolYearId;

  const Periode({required this.id, required this.nom, required this.schoolYearId});

  factory Periode.fromJson(Map<String, dynamic> j) => Periode(
        id:           j['id'] as int,
        nom:          j['label'] as String,
        schoolYearId: j['school_year_id'] as int,
      );
}
