/// Un devoir tel que renvoyé par HomeworkResource
/// (backend/app/Http/Resources/Api/V1/HomeworkResource.php).
class Homework {
  final int id;
  final String title;
  final String? instructions;
  final String? dueDate;
  final String? publishedAt;
  final String? subjectName;
  final String? schoolClassName;
  final String? teacherName;

  const Homework({
    required this.id,
    required this.title,
    this.instructions,
    this.dueDate,
    this.publishedAt,
    this.subjectName,
    this.schoolClassName,
    this.teacherName,
  });

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
        id:              j['id'] as int,
        title:           j['title'] as String,
        instructions:    j['instructions'] as String?,
        dueDate:         j['due_date'] as String?,
        publishedAt:     j['published_at'] as String?,
        subjectName:     (j['subject'] as Map?)?['name'] as String?,
        schoolClassName: (j['school_class'] as Map?)?['name'] as String?,
        teacherName:     j['teacher_name'] as String?,
      );
}
