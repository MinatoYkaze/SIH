import '../core/networking/api_client.dart';
import '../models/sponsorship.dart';

class SponsorshipService {
  final ApiClient _client;

  SponsorshipService(this._client);

  Future<SponsorshipModel> createSponsorship(
    String issueId,
    SponsorshipCreate sponsorship,
  ) async {
    final response = await _client.post(
      '/issues/$issueId/sponsorships',
      body: sponsorship.toJson(),
    );
    return SponsorshipModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<SponsorshipModel>> listSponsorships(String issueId) async {
    final response = await _client.get('/issues/$issueId/sponsorships');
    return (response as List<dynamic>)
        .map((s) => SponsorshipModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<SponsorshipModel> updateSponsorship(
    String sponsorshipId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '/sponsorships/$sponsorshipId',
      body: updates,
    );
    return SponsorshipModel.fromJson(response as Map<String, dynamic>);
  }
}
