class User {
  final int id;
  final int ecoleId;
  final String telephone;
  final String? prenom;
  final String? nom;
  final String role;
  final bool actif;

  const User({
    required this.id,
    required this.ecoleId,
    required this.telephone,
    this.prenom,
    this.nom,
    required this.role,
    required this.actif,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id:        j['id'] as int,
        ecoleId:   j['ecole_id'] as int,
        telephone: j['telephone'] as String,
        prenom:    j['prenom'] as String?,
        nom:       j['nom'] as String?,
        role:      j['role'] as String,
        actif:     j['actif'] == true || j['actif'] == 1,
      );

  String get nomComplet => '${prenom ?? ''} ${nom ?? ''}'.trim();
  bool get estParent    => role == 'parent';
  bool get estEnseignant => role == 'teacher';
  bool get estAdmin     => role == 'school_admin' || role == 'super_admin';
}
