import '../models/conversation.dart';
import '../models/message_app.dart';
import '../models/messaging_contact.dart';
import 'api_service.dart';

/// Messagerie parent ↔ prof/direction (/api/v1/admin/conversations) — le
/// préfixe "admin" est trompeur : ces routes sont ouvertes à tout
/// utilisateur ayant les permissions message.view/message.send, y compris
/// un parent (voir ConversationPolicy).
class MessagingService {
  Future<List<Conversation>> getConversations() async {
    final data = await apiService.get('/admin/conversations');
    return (data['data'] as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageApp>> getMessages(int conversationId) async {
    final data = await apiService.get('/admin/conversations/$conversationId/messages');
    return (data['data'] as List).map((e) => MessageApp.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Conversation> creerConversation({
    required int participantUserId,
    required String body,
    String? subject,
    int? studentId,
  }) async {
    final data = await apiService.post('/admin/conversations', body: {
      'participant_user_id': participantUserId,
      'body': body,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (studentId != null) 'student_id': studentId,
    });
    return Conversation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> envoyerMessage(int conversationId, String body) async {
    await apiService.post('/admin/conversations/$conversationId/messages', body: {'body': body});
  }

  Future<({List<MessagingContact> profs, List<MessagingContact> direction})> getContacts(int studentId) async {
    final data = await apiService.get('/children/$studentId/messaging-contacts');
    final profs = (data['teachers'] as List).map((e) => MessagingContact.fromJson(e as Map<String, dynamic>)).toList();
    final direction = (data['direction'] as List).map((e) => MessagingContact.fromJson(e as Map<String, dynamic>)).toList();
    return (profs: profs, direction: direction);
  }
}
