import 'tenant_branding.dart';

class UserClasse {
  final int id;
  final String name;

  const UserClasse({required this.id, required this.name});

  factory UserClasse.fromJson(Map<String, dynamic> j) => UserClasse(
        id:   j['id'] as int,
        name: j['name'] as String,
      );
}

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  final TenantBranding? tenant;
  final List<UserClasse> classes;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
    this.tenant,
    this.classes = const [],
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id:    j['id'] as int,
        name:  j['name'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        roles: (j['roles'] as List?)?.map((r) => r.toString()).toList() ?? const [],
        tenant: j['tenant'] is Map ? TenantBranding.fromJson(j['tenant'] as Map<String, dynamic>) : null,
        classes: (j['classes'] as List?)
                ?.map((c) => UserClasse.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  bool get estParent      => roles.contains('parent');
  bool get estEnseignant  => roles.contains('teacher');
  bool get estAdmin       => roles.contains('school_admin') || roles.contains('direction');
  bool get estSurveillant => roles.contains('surveillant');

  /// Un enseignant ou un surveillant peut saisir des devoirs, remarques,
  /// absences ; un parent est en lecture (sauf messagerie et justification).
  bool get faitPartieDuPersonnel => estEnseignant || estAdmin || estSurveillant;
}
