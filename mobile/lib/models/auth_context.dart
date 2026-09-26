/// Une école accessible avec le même compte parent (parent_identity côté
/// API) — docs/PRODUCT_ARCHITECTURE.md §9. Permet à un parent ayant des
/// enfants dans plusieurs écoles de basculer sans ressaisir son mot de passe.
class AuthContext {
  final int userId;
  final int tenantId;
  final String? tenantName;

  const AuthContext({required this.userId, required this.tenantId, this.tenantName});

  factory AuthContext.fromJson(Map<String, dynamic> j) => AuthContext(
        userId:     j['user_id'] as int,
        tenantId:   j['tenant_id'] as int,
        tenantName: j['tenant_name'] as String?,
      );
}
