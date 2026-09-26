class TeacherAssignmentAdmin {
  final int schoolClassId;
  final String? schoolClassName;
  final int subjectId;
  final String? subjectName;

  const TeacherAssignmentAdmin({
    required this.schoolClassId,
    this.schoolClassName,
    required this.subjectId,
    this.subjectName,
  });

  factory TeacherAssignmentAdmin.fromJson(Map<String, dynamic> j) => TeacherAssignmentAdmin(
        schoolClassId: j['school_class_id'] as int,
        schoolClassName: j['school_class_name'] as String?,
        subjectId: j['subject_id'] as int,
        subjectName: j['subject_name'] as String?,
      );

  Map<String, dynamic> toJson() => {'school_class_id': schoolClassId, 'subject_id': subjectId};
}

/// Un professeur, tel que renvoyé par TeacherResource (gestion direction).
class TeacherAdmin {
  final int id;
  final int userId;
  final String? name;
  final String? email;
  final String? employeeNumber;
  final List<TeacherAssignmentAdmin> assignments;

  const TeacherAdmin({
    required this.id,
    required this.userId,
    this.name,
    this.email,
    this.employeeNumber,
    this.assignments = const [],
  });

  factory TeacherAdmin.fromJson(Map<String, dynamic> j) => TeacherAdmin(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        name: j['name'] as String?,
        email: j['email'] as String?,
        employeeNumber: j['employee_number'] as String?,
        assignments: (j['assignments'] as List?)
                ?.map((a) => TeacherAssignmentAdmin.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
