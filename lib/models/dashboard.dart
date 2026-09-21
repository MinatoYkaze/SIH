import 'issue.dart';

class CitizenDashboardModel {
  final int totalReported;
  final int verifiedIssues;
  final int inProgressIssues;
  final int resolvedIssues;
  final List<IssueModel> recentReportedIssues;

  const CitizenDashboardModel({
    required this.totalReported,
    required this.verifiedIssues,
    required this.inProgressIssues,
    required this.resolvedIssues,
    this.recentReportedIssues = const [],
  });

  factory CitizenDashboardModel.fromJson(Map<String, dynamic> json) {
    final recent = (json['recent_reported_issues'] as List<dynamic>?)
            ?.map((i) => IssueModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return CitizenDashboardModel(
      totalReported: json['total_reported'] as int? ?? 0,
      verifiedIssues: json['verified_issues'] as int? ?? 0,
      inProgressIssues: json['in_progress_issues'] as int? ?? 0,
      resolvedIssues: json['resolved_issues'] as int? ?? 0,
      recentReportedIssues: recent,
    );
  }
}

class StudentDashboardModel {
  final int applicationsCount;
  final int acceptedApplications;
  final int assignedIssues;
  final int activeIssues;
  final int submittedSolutions;
  final int selectedOrReviewedSolutions;
  final List<IssueModel> recentAssignedIssues;

  const StudentDashboardModel({
    required this.applicationsCount,
    required this.acceptedApplications,
    required this.assignedIssues,
    required this.activeIssues,
    required this.submittedSolutions,
    required this.selectedOrReviewedSolutions,
    this.recentAssignedIssues = const [],
  });

  factory StudentDashboardModel.fromJson(Map<String, dynamic> json) {
    final recent = (json['recent_assigned_issues'] as List<dynamic>?)
            ?.map((i) => IssueModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return StudentDashboardModel(
      applicationsCount: json['applications_count'] as int? ?? 0,
      acceptedApplications: json['accepted_applications'] as int? ?? 0,
      assignedIssues: json['assigned_issues'] as int? ?? 0,
      activeIssues: json['active_issues'] as int? ?? 0,
      submittedSolutions: json['submitted_solutions'] as int? ?? 0,
      selectedOrReviewedSolutions:
          json['selected_or_reviewed_solutions'] as int? ?? 0,
      recentAssignedIssues: recent,
    );
  }
}

class IndustryDashboardModel {
  final int issuesAvailableForSupport;
  final int sponsoredIssuesCount;
  final double totalSponsoredAmount;
  final int reviewedSolutionsCount;
  final int activeSupportedProjects;

  const IndustryDashboardModel({
    required this.issuesAvailableForSupport,
    required this.sponsoredIssuesCount,
    required this.totalSponsoredAmount,
    required this.reviewedSolutionsCount,
    required this.activeSupportedProjects,
  });

  factory IndustryDashboardModel.fromJson(Map<String, dynamic> json) {
    return IndustryDashboardModel(
      issuesAvailableForSupport:
          json['issues_available_for_support'] as int? ?? 0,
      sponsoredIssuesCount: json['sponsored_issues_count'] as int? ?? 0,
      totalSponsoredAmount: json['total_sponsored_amount'] != null
          ? (json['total_sponsored_amount'] as num).toDouble()
          : 0.0,
      reviewedSolutionsCount: json['reviewed_solutions_count'] as int? ?? 0,
      activeSupportedProjects:
          json['active_supported_projects'] as int? ?? 0,
    );
  }
}
