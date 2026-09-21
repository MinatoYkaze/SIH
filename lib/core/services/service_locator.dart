import '../auth/auth_manager.dart';
import '../networking/api_client.dart';
import '../../services/application_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/evidence_service.dart';
import '../../services/issue_service.dart';
import '../../services/profile_service.dart';
import '../../services/solution_service.dart';
import '../../services/sponsorship_service.dart';

class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();

  ServiceLocator._internal() {
    _apiClient = ApiClient(
      tokenProvider: () async => AuthManager.instance.currentToken,
    );
    profileService = ProfileService(_apiClient);
    issueService = IssueService(_apiClient);
    applicationService = ApplicationService(_apiClient);
    solutionService = SolutionService(_apiClient);
    evidenceService = EvidenceService(_apiClient);
    sponsorshipService = SponsorshipService(_apiClient);
    dashboardService = DashboardService(_apiClient);
  }

  late final ApiClient _apiClient;
  late final ProfileService profileService;
  late final IssueService issueService;
  late final ApplicationService applicationService;
  late final SolutionService solutionService;
  late final EvidenceService evidenceService;
  late final SponsorshipService sponsorshipService;
  late final DashboardService dashboardService;

  AuthManager get authManager => AuthManager.instance;
}
