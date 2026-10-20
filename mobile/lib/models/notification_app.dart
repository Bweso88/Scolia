/// Une notification de l'historique en base (NotificationController côté
/// API), déclenchée par devoir/absence/message/annonce
/// (docs/PRODUCT_ARCHITECTURE.md §16).
class NotificationApp {
  final String id;
  final String? type;
  final String? titre;
  final String? corps;
  final String? readAt;
  final String createdAt;

  const NotificationApp({
    required this.id,
    this.type,
    this.titre,
    this.corps,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationApp.fromJson(Map<String, dynamic> j) => NotificationApp(
        id:        j['id'].toString(),
        type:      j['type'] as String?,
        titre:     j['title'] as String?,
        corps:     j['body'] as String?,
        readAt:    j['read_at'] as String?,
        createdAt: j['created_at'] as String,
      );

  bool get lue => readAt != null;
}
