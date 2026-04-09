import '../models/evenement.dart';
import 'api_service.dart';

class EvenementsService {
  Future<List<Evenement>> getEvenements({bool futur = false}) async {
    final data = await apiService.get('/evenements', params: {'futur': futur ? '1' : '0'});
    return (data['evenements'] as List).map((e) => Evenement.fromJson(e as Map<String, dynamic>)).toList();
  }
}
