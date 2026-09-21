import '../core/networking/api_client.dart';
import '../models/solution.dart';

class SolutionService {
  final ApiClient _client;

  SolutionService(this._client);

  Future<SolutionModel> submitSolution(
    String issueId,
    SolutionCreate solution,
  ) async {
    final response = await _client.post(
      '/issues/$issueId/solutions',
      body: solution.toJson(),
    );
    return SolutionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<SolutionModel>> listSolutionsForIssue(String issueId) async {
    final response = await _client.get('/issues/$issueId/solutions');
    return (response as List<dynamic>)
        .map((s) => SolutionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<SolutionModel>> getMySolutions() async {
    final response = await _client.get('/issues/me/solutions');
    return (response as List<dynamic>)
        .map((s) => SolutionModel.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<SolutionModel> getSolutionById(String solutionId) async {
    final response = await _client.get('/solutions/$solutionId');
    return SolutionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<SolutionModel> updateSolution(
    String solutionId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _client.patch(
      '/solutions/$solutionId',
      body: updates,
    );
    return SolutionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<SolutionReviewModel> submitReview(
    String solutionId,
    SolutionReviewCreate review,
  ) async {
    final response = await _client.post(
      '/solutions/$solutionId/reviews',
      body: review.toJson(),
    );
    return SolutionReviewModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<SolutionReviewModel>> listReviews(String solutionId) async {
    final response = await _client.get('/solutions/$solutionId/reviews');
    return (response as List<dynamic>)
        .map((r) => SolutionReviewModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }
}
