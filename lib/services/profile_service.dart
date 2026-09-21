import '../core/networking/api_client.dart';
import '../models/profile.dart';

class ProfileService {
  final ApiClient _client;

  ProfileService(this._client);

  Future<ProfileModel> getMyProfile() async {
    final response = await _client.get('/profiles/me');
    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ProfileModel> createProfile(ProfileCreate profile) async {
    final response = await _client.post('/profiles/me', body: profile.toJson());
    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> updates) async {
    final response = await _client.patch('/profiles/me', body: updates);
    return ProfileModel.fromJson(response as Map<String, dynamic>);
  }
}
