import '../models/remarque.dart';
import 'api_service.dart';

class RemarquesService {
  Future<List<Remarque>> getRemarques({int page = 1}) async {
    final data = await apiService.get('/remarques', params: {'page': page});
    return (data['items'] as List).map((e) => Remarque.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerRemarque(Map<String, dynamic> corps) async {
    await apiService.post('/remarques', body: corps);
  }

  Future<void> marquerLue(int id) async {
    await apiService.post('/remarques/$id/lire');
  }
}
