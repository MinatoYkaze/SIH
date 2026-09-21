import '../core/networking/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  final ApiClient _client;

  DashboardService(this._client);

  Future<CitizenDashboardModel> getCitizenDashboard() async {
    final response = await _client.get('/dashboard/citizen');
    return CitizenDashboardModel.fromJson(response as Map<String, dynamic>);
  }

  Future<StudentDashboardModel> getStudentDashboard() async {
    final response = await _client.get('/dashboard/student');
    return StudentDashboardModel.fromJson(response as Map<String, dynamic>);
  }

  Future<IndustryDashboardModel> getIndustryDashboard() async {
    final response = await _client.get('/dashboard/industry');
    return IndustryDashboardModel.fromJson(response as Map<String, dynamic>);
  }
}
