class NotificationApp {
  final int id;
  final String titre;
  final String? corps;
  final String type;
  final int? referenceId;
  final bool lue;
  final String createdAt;

  const NotificationApp({
    required this.id,
    required this.titre,
    this.corps,
    required this.type,
    this.referenceId,
    required this.lue,
    required this.createdAt,
  });

  factory NotificationApp.fromJson(Map<String, dynamic> j) => NotificationApp(
        id:          j['id'] as int,
        titre:       j['titre'] as String,
        corps:       j['corps'] as String?,
        type:        j['type'] as String? ?? 'autre',
        referenceId: j['reference_id'] as int?,
        lue:         j['lue'] == true || j['lue'] == 1,
        createdAt:   j['created_at'] as String,
      );
}
