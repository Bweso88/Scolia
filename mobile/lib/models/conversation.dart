import 'student.dart' show SchoolClassRef;

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

/// Élève concerné par un fil parent ↔ enseignant (absent pour un fil
/// général avec la direction).
class ConversationStudent {
  final String firstName;
  final String lastName;
  final SchoolClassRef? schoolClass;

  const ConversationStudent({required this.firstName, required this.lastName, this.schoolClass});

  factory ConversationStudent.fromJson(Map<String, dynamic> j) => ConversationStudent(
        firstName: j['first_name'] as String,
        lastName: j['last_name'] as String,
        schoolClass: j['school_class'] is Map
            ? SchoolClassRef.fromJson(j['school_class'] as Map<String, dynamic>)
            : null,
      );

  String get nomComplet => '$firstName $lastName';
}

class Conversation {
  final int id;
  final String? subject;
  final List<ConversationParticipant> participants;
  final ConversationStudent? student;
  final String? lastMessage;
  final String? createdAt;

  const Conversation({
    required this.id,
    this.subject,
    this.participants = const [],
    this.student,
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
        student: j['student'] is Map ? ConversationStudent.fromJson(j['student'] as Map<String, dynamic>) : null,
        lastMessage: j['last_message'] as String?,
        createdAt: j['created_at'] as String?,
      );

  /// Nom à afficher pour ce fil, en excluant l'utilisateur courant.
  String interlocuteur(int monId) {
    final autres = participants.where((p) => p.id != monId).toList();
    if (autres.isEmpty) return subject ?? 'Conversation';
    return autres.map((p) => p.name).join(', ');
  }

  /// "À propos de {élève}, {classe}", ou null si ce fil n'est pas lié à
  /// un élève précis (ex. question générale à la direction).
  String? get contexteEleve {
    if (student == null) return null;
    final classe = student!.schoolClass != null ? ', ${student!.schoolClass!.name}' : '';
    return 'À propos de ${student!.nomComplet}$classe';
  }
}
