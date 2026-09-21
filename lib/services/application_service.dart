import '../core/networking/api_client.dart';
import '../models/application.dart';
import '../models/issue.dart';

class ApplicationService {
  final ApiClient _client;

  ApplicationService(this._client);

  Future<ApplicationModel> applyToIssue(String issueId, String proposal) async {
    final response = await _client.post(
      '/issues/$issueId/applications',
      body: ApplicationCreate(proposal: proposal).toJson(),
    );
    return ApplicationModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ApplicationModel>> listApplicationsForIssue(String issueId) async {
    final response = await _client.get('/issues/$issueId/applications');
    return (response as List<dynamic>)
        .map((a) => ApplicationModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<ApplicationModel>> getMyApplications() async {
    final response = await _client.get('/applications/me');
    return (response as List<dynamic>)
        .map((a) => ApplicationModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<ApplicationModel> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    final response = await _client.patch(
      '/applications/$applicationId',
      body: {'status': status},
    );
    return ApplicationModel.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueModel> assignStudentToIssue(
    String issueId,
    String studentId,
  ) async {
    final response = await _client.post(
      '/issues/$issueId/assign',
      body: {'student_id': studentId},
    );
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }
}
