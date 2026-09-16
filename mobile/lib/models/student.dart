class SchoolClassRef {
  final int id;
  final String name;

  const SchoolClassRef({required this.id, required this.name});

  factory SchoolClassRef.fromJson(Map<String, dynamic> j) => SchoolClassRef(
        id:   j['id'] as int,
        name: j['name'] as String,
      );
}

/// Un élève tel que renvoyé par StudentResource (voir
/// backend/app/Http/Resources/Api/V1/StudentResource.php). Pour un parent,
/// la liste vient de GET /children (ses propres enfants uniquement) ; pour
/// le personnel, de GET /admin/students.
class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String? enrollmentNumber;
  final String status;
  final SchoolClassRef? schoolClass;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.enrollmentNumber,
    required this.status,
    this.schoolClass,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id:               j['id'] as int,
        firstName:        j['first_name'] as String,
        lastName:         j['last_name'] as String,
        enrollmentNumber: j['enrollment_number'] as String?,
        status:           j['status'] as String? ?? 'active',
        schoolClass: j['school_class'] is Map
            ? SchoolClassRef.fromJson(j['school_class'] as Map<String, dynamic>)
            : null,
      );

  String get nomComplet => '$firstName $lastName';
  bool get actif => status == 'active';
}
