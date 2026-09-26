/// Un fil de discussion parent ↔ prof/direction (docs/PRODUCT_ARCHITECTURE.md
/// §7), tel que renvoyé par ConversationResource.
class ConversationParticipant {
  final int id;
  final String name;

  const ConversationParticipant({required this.id, required this.name});

  factory ConversationParticipant.fromJson(Map<String, dynamic> j) => ConversationParticipant(
        id: j['id'] as int,
        name: j['name'] as String,
      );
}

class Conversation {
  final int id;
  final String? subject;
  final List<ConversationParticipant> participants;
  final String? lastMessage;
  final String? createdAt;

  const Conversation({
    required this.id,
    this.subject,
    this.participants = const [],
    this.lastMessage,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as int,
        subject: j['subject'] as String?,
        participants: (j['participants'] as List?)
                ?.map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        lastMessage: j['last_message'] as String?,
        createdAt: j['created_at'] as String?,
      );

  /// Nom à afficher pour ce fil, en excluant l'utilisateur courant.
  String interlocuteur(int monId) {
    final autres = participants.where((p) => p.id != monId).toList();
    if (autres.isEmpty) return subject ?? 'Conversation';
    return autres.map((p) => p.name).join(', ');
  }
}
