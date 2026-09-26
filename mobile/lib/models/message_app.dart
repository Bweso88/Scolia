/// Un message dans un fil de discussion, tel que renvoyé par MessageResource.
class MessageApp {
  final int id;
  final String body;
  final int senderId;
  final String? senderName;
  final String? createdAt;

  const MessageApp({
    required this.id,
    required this.body,
    required this.senderId,
    this.senderName,
    this.createdAt,
  });

  factory MessageApp.fromJson(Map<String, dynamic> j) => MessageApp(
        id: j['id'] as int,
        body: j['body'] as String,
        senderId: j['sender_id'] as int,
        senderName: j['sender_name'] as String?,
        createdAt: j['created_at'] as String?,
      );
}
