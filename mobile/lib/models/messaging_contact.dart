/// Destinataire possible pour un parent (prof de la classe de son enfant,
/// ou membre de la direction) — voir ChildrenController::messagingContacts.
class MessagingContact {
  final int userId;
  final String name;
  final String? subject;
  final bool contactable;

  const MessagingContact({
    required this.userId,
    required this.name,
    this.subject,
    this.contactable = true,
  });

  factory MessagingContact.fromJson(Map<String, dynamic> j) => MessagingContact(
        userId: j['user_id'] as int,
        name: j['name'] as String,
        subject: j['subject'] as String?,
        contactable: j['contactable'] as bool? ?? true,
      );
}
