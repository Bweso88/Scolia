/// Une classe telle que renvoyée par SchoolClassResource (gestion
/// direction), à ne pas confondre avec SchoolClassRef (student.dart),
/// qui ne porte que id/name pour l'affichage simple.
class SchoolClassAdmin {
  final int id;
  final String name;
  final String? level;
  final int? schoolYearId;
  final String? schoolYearLabel;
  final int? homeroomTeacherId;
  final String? homeroomTeacherName;
  final int? studentsCount;

  const SchoolClassAdmin({
    required this.id,
    required this.name,
    this.level,
    this.schoolYearId,
    this.schoolYearLabel,
    this.homeroomTeacherId,
    this.homeroomTeacherName,
    this.studentsCount,
  });

  factory SchoolClassAdmin.fromJson(Map<String, dynamic> j) => SchoolClassAdmin(
        id: j['id'] as int,
        name: j['name'] as String,
        level: j['level'] as String?,
        schoolYearId: (j['school_year'] as Map?)?['id'] as int?,
        schoolYearLabel: (j['school_year'] as Map?)?['label'] as String?,
        homeroomTeacherId: (j['homeroom_teacher'] as Map?)?['id'] as int?,
        homeroomTeacherName: (j['homeroom_teacher'] as Map?)?['name'] as String?,
        studentsCount: j['students_count'] as int?,
      );
}
