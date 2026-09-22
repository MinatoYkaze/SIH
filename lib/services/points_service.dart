import '../core/networking/api_client.dart';
import '../models/points.dart';

class PointsService {
  final ApiClient _client;

  PointsService(this._client);

  Future<PointsModel> getMyPoints() async {
    final response = await _client.get('/points/me');
    return PointsModel.fromJson(response as Map<String, dynamic>);
  }
}
