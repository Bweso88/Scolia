/// Une observation de comportement, telle que renvoyée par
/// BehaviorObservationResource (docs/PRODUCT_ARCHITECTURE.md §6, module
/// Comportement).
class Remarque {
  final int id;
  final int studentId;
  final String category;
  final String title;
  final String? description;
  final String? occurredAt;
  final bool visibleToParent;
  final String? authorName;

  const Remarque({
    required this.id,
    required this.studentId,
    required this.category,
    required this.title,
    this.description,
    this.occurredAt,
    required this.visibleToParent,
    this.authorName,
  });

  factory Remarque.fromJson(Map<String, dynamic> j) => Remarque(
        id:              j['id'] as int,
        studentId:       j['student_id'] as int,
        category:        j['category'] as String? ?? 'note_generale',
        title:           j['title'] as String,
        description:     j['description'] as String?,
        occurredAt:      j['occurred_at'] as String?,
        visibleToParent: j['visible_to_parent'] as bool? ?? true,
        authorName:      j['author_name'] as String?,
      );
}
