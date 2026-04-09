import '../models/message_liaison.dart';
import 'api_service.dart';

class LiaisonService {
  Future<List<MessageLiaison>> getMessages({int page = 1}) async {
    final data = await apiService.get('/liaison', params: {'page': page});
    return (data['items'] as List).map((e) => MessageLiaison.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MessageLiaison> getMessage(int id) async {
    final data = await apiService.get('/liaison/$id');
    return MessageLiaison.fromJson(data['message'] as Map<String, dynamic>);
  }

  Future<void> creerMessage(Map<String, dynamic> corps) async {
    await apiService.post('/liaison', body: corps);
  }

  Future<void> accuserReception(int id) async {
    await apiService.post('/liaison/$id/accuser');
  }
}
