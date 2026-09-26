/// Un lien parent ↔ élève, tel que renvoyé par StudentGuardianResource.
class StudentGuardianAdmin {
  final int id;
  final int userId;
  final String? name;
  final String? email;
  final String relationshipType;
  final bool isPrimaryContact;

  const StudentGuardianAdmin({
    required this.id,
    required this.userId,
    this.name,
    this.email,
    required this.relationshipType,
    this.isPrimaryContact = false,
  });

  factory StudentGuardianAdmin.fromJson(Map<String, dynamic> j) => StudentGuardianAdmin(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        name: j['name'] as String?,
        email: j['email'] as String?,
        relationshipType: j['relationship_type'] as String,
        isPrimaryContact: j['is_primary_contact'] as bool? ?? false,
      );
}
