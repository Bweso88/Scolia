/// Un événement du calendrier scolaire, tel que renvoyé par
/// AcademicEventResource (docs/PRODUCT_ARCHITECTURE.md — écran "Agenda").
class AcademicEvent {
  final int id;
  final String title;
  final String? description;
  final String startDate;
  final String? endDate;
  final String category;

  const AcademicEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.category,
  });

  factory AcademicEvent.fromJson(Map<String, dynamic> j) => AcademicEvent(
        id:          j['id'] as int,
        title:       j['title'] as String,
        description: j['description'] as String?,
        startDate:   j['start_date'] as String,
        endDate:     j['end_date'] as String?,
        category:    j['category'] as String? ?? 'autre',
      );
}

/// Catégories d'événements — une classification générale, indépendante de
/// l'organisation propre à chaque école.
const categoriesEvenement = {
  'vacances':   'Vacances scolaires',
  'examen':     'Examens & Tests',
  'evenement':  'Événement',
  'reunion':    'Réunion',
  'autre':      'Autre',
};
