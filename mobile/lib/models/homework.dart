/// Une pièce jointe de devoir (backend/app/Models/HomeworkAttachment.php).
class HomeworkAttachment {
  final int id;
  final String fileName;
  final int sizeBytes;
  final String url;

  const HomeworkAttachment({required this.id, required this.fileName, required this.sizeBytes, required this.url});

  factory HomeworkAttachment.fromJson(Map<String, dynamic> j) => HomeworkAttachment(
        id:        j['id'] as int,
        fileName:  j['file_name'] as String,
        sizeBytes: j['size_bytes'] as int,
        url:       j['url'] as String,
      );

  String get tailleAffichee {
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} Ko';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}

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
  final String status;
  final List<HomeworkAttachment> attachments;

  const Homework({
    required this.id,
    required this.title,
    this.instructions,
    this.dueDate,
    this.publishedAt,
    this.subjectName,
    this.schoolClassName,
    this.teacherName,
    this.status = 'pending',
    this.attachments = const [],
  });

  bool get estFait => status == 'done';

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
        id:              j['id'] as int,
        title:           j['title'] as String,
        instructions:    j['instructions'] as String?,
        dueDate:         j['due_date'] as String?,
        publishedAt:     j['published_at'] as String?,
        subjectName:     (j['subject'] as Map?)?['name'] as String?,
        schoolClassName: (j['school_class'] as Map?)?['name'] as String?,
        teacherName:     j['teacher_name'] as String?,
        status:          j['status'] as String? ?? 'pending',
        attachments: (j['attachments'] as List?)
                ?.map((a) => HomeworkAttachment.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Homework copierAvecStatus(String nouveauStatus) => Homework(
        id: id,
        title: title,
        instructions: instructions,
        dueDate: dueDate,
        publishedAt: publishedAt,
        subjectName: subjectName,
        schoolClassName: schoolClassName,
        teacherName: teacherName,
        status: nouveauStatus,
        attachments: attachments,
      );
}
