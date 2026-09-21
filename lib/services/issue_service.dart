import '../core/networking/api_client.dart';
import '../models/issue.dart';

class IssueService {
  final ApiClient _client;

  IssueService(this._client);

  Future<IssueModel> createIssue(IssueCreate issue) async {
    final response = await _client.post('/issues', body: issue.toJson());
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueListResponse> listIssues({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? status,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (minLat != null) query['min_lat'] = minLat;
    if (maxLat != null) query['max_lat'] = maxLat;
    if (minLon != null) query['min_lon'] = minLon;
    if (maxLon != null) query['max_lon'] = maxLon;

    final response = await _client.get('/issues', queryParameters: query);
    return IssueListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueListResponse> getMyReportedIssues({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/issues/me/reported',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return IssueListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueListResponse> getMyAssignedIssues({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      '/issues/me/assigned',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return IssueListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueModel> getIssueById(String issueId) async {
    final response = await _client.get('/issues/$issueId');
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<IssueModel> updateIssue(
    String issueId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch('/issues/$issueId', body: updates);
    return IssueModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteIssue(String issueId) async {
    await _client.delete('/issues/$issueId');
  }

  Future<IssueMediaModel> attachMedia(
    String issueId,
    String mediaUrl, {
    String mediaType = 'image',
  }) async {
    final response = await _client.post(
      '/issues/$issueId/media',
      body: {
        'media_url': mediaUrl,
        'media_type': mediaType,
      },
    );
    return IssueMediaModel.fromJson(response as Map<String, dynamic>);
  }
}
