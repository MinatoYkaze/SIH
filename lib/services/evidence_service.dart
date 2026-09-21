import '../core/networking/api_client.dart';
import '../models/evidence.dart';

class EvidenceService {
  final ApiClient _client;

  EvidenceService(this._client);

  Future<EvidenceModel> createEvidence(
    String issueId,
    EvidenceCreate evidence,
  ) async {
    final response = await _client.post(
      '/issues/$issueId/evidence',
      body: evidence.toJson(),
    );
    return EvidenceModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<EvidenceModel>> listEvidence(String issueId) async {
    final response = await _client.get('/issues/$issueId/evidence');
    return (response as List<dynamic>)
        .map((e) => EvidenceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteEvidence(String evidenceId) async {
    await _client.delete('/evidence/$evidenceId');
  }
}
