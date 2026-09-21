import 'package:flutter_test/flutter_test.dart';
import 'package:transition_platform/core/networking/api_exception.dart';
import 'package:transition_platform/models/application.dart';
import 'package:transition_platform/models/dashboard.dart';
import 'package:transition_platform/models/evidence.dart';
import 'package:transition_platform/models/issue.dart';
import 'package:transition_platform/models/profile.dart';
import 'package:transition_platform/models/solution.dart';
import 'package:transition_platform/models/sponsorship.dart';

void main() {
  group('ProfileModel Tests', () {
    test('ProfileModel parses from JSON correctly', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'Aarav Sharma',
        'role': 'citizen',
        'phone_number': '+91 9876543210',
        'avatar_url': 'https://example.com/avatar.jpg',
        'location': 'Sector 18, Metro Corridor',
        'created_at': '2026-09-21T10:00:00Z',
        'updated_at': '2026-09-21T11:00:00Z',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(profile.name, 'Aarav Sharma');
      expect(profile.role, 'citizen');
      expect(profile.phoneNumber, '+91 9876543210');
      expect(profile.location, 'Sector 18, Metro Corridor');
      expect(profile.createdAt, isNotNull);
    });

    test('ProfileCreate serializes correctly', () {
      const create = ProfileCreate(
        name: 'Rohan Verma',
        role: 'student',
        location: 'Engineering Campus',
      );
      final map = create.toJson();
      expect(map['name'], 'Rohan Verma');
      expect(map['role'], 'student');
      expect(map['location'], 'Engineering Campus');
    });
  });

  group('IssueModel Tests', () {
    test('IssueModel parses full JSON with media correctly', () {
      final json = {
        'id': '987e6543-e89b-12d3-a456-426614174000',
        'title': 'Road Infrastructure Sinkhole',
        'description': 'Large crater blocking left lane at Sector 18',
        'category': 'Road damage',
        'priority': 'HIGH',
        'latitude': 28.5355,
        'longitude': 77.3910,
        'address': 'Ward 14 • Sector 18 Junction',
        'reporter_id': '111e1111-e89b-12d3-a456-426614174000',
        'assigned_student_id': '222e2222-e89b-12d3-a456-426614174000',
        'category_confidence': 0.94,
        'status': 'AI_CLASSIFIED',
        'created_at': '2026-09-21T08:00:00Z',
        'updated_at': '2026-09-21T09:00:00Z',
        'media': [
          {
            'id': 'med-1',
            'issue_id': '987e6543-e89b-12d3-a456-426614174000',
            'media_url': 'https://example.com/pothole.jpg',
            'media_type': 'image',
          }
        ],
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.id, '987e6543-e89b-12d3-a456-426614174000');
      expect(issue.title, 'Road Infrastructure Sinkhole');
      expect(issue.displayCategory, 'Road damage');
      expect(issue.displayPriority, 'HIGH');
      expect(issue.displayStatus, 'AI CLASSIFIED');
      expect(issue.latitude, 28.5355);
      expect(issue.longitude, 77.3910);
      expect(issue.categoryConfidence, 0.94);
      expect(issue.media.length, 1);
      expect(issue.firstImageUrl, 'https://example.com/pothole.jpg');
    });

    test('IssueCreate serializes properly without nulls', () {
      const create = IssueCreate(
        title: 'Broken Streetlight',
        description: 'Streetlight pole 42 sparking and dark at night',
        category: 'Electricity',
        priority: 'CRITICAL',
        latitude: 28.5356,
        longitude: 77.3911,
      );

      final map = create.toJson();
      expect(map['title'], 'Broken Streetlight');
      expect(map['category'], 'Electricity');
      expect(map['priority'], 'CRITICAL');
      expect(map['latitude'], 28.5356);
      expect(map['longitude'], 77.3911);
    });
  });

  group('Application & Solution Tests', () {
    test('ApplicationModel parses correctly', () {
      final json = {
        'id': 'app-1',
        'issue_id': 'issue-1',
        'student_id': 'student-1',
        'proposal': 'Apply cold asphalt emulsion and compact with hand roller.',
        'status': 'PENDING',
        'created_at': '2026-09-21T09:30:00Z',
        'updated_at': '2026-09-21T09:30:00Z',
      };

      final app = ApplicationModel.fromJson(json);
      expect(app.id, 'app-1');
      expect(app.proposal, contains('cold asphalt'));
      expect(app.status, 'PENDING');
    });

    test('SolutionModel and SolutionReviewModel parse correctly', () {
      final json = {
        'id': 'sol-1',
        'issue_id': 'issue-1',
        'student_id': 'student-1',
        'title': 'Cold-Pour Asphalt Emulsion Kit',
        'description': 'Rapid curing bitumen mix suitable for monsoon conditions.',
        'pdf_url': 'https://example.com/report.pdf',
        'prototype_url': 'https://github.com/example/repo',
        'status': 'UNDER_REVIEW',
        'created_at': '2026-09-21T10:00:00Z',
        'updated_at': '2026-09-21T10:00:00Z',
        'reviews': [
          {
            'id': 'rev-1',
            'solution_id': 'sol-1',
            'reviewer_id': 'mentor-1',
            'rating': 5,
            'feedback': 'Great technical proposal and safety specs.',
            'created_at': '2026-09-21T10:30:00Z',
          }
        ],
      };

      final sol = SolutionModel.fromJson(json);
      expect(sol.id, 'sol-1');
      expect(sol.reviews.length, 1);
      expect(sol.reviews.first.rating, 5);
      expect(sol.reviews.first.feedback, contains('Great technical'));
    });
  });

  group('Evidence & Sponsorship Tests', () {
    test('EvidenceModel parses correctly', () {
      final json = {
        'id': 'evi-1',
        'issue_id': 'issue-1',
        'student_id': 'student-1',
        'media_url': 'https://example.com/after.jpg',
        'description': 'Completed compaction and sealed asphalt surface.',
        'evidence_type': 'AFTER',
        'created_at': '2026-09-21T12:00:00Z',
      };

      final evi = EvidenceModel.fromJson(json);
      expect(evi.id, 'evi-1');
      expect(evi.evidenceType, 'AFTER');
      expect(evi.mediaUrl, 'https://example.com/after.jpg');
    });

    test('SponsorshipModel parses correctly', () {
      final json = {
        'id': 'spon-1',
        'issue_id': 'issue-1',
        'industrialist_id': 'ind-1',
        'amount': 420.0,
        'message': 'Grant committed by Apex Infra Ventures.',
        'status': 'PLEDGED',
        'created_at': '2026-09-21T11:00:00Z',
        'updated_at': '2026-09-21T11:00:00Z',
      };

      final spon = SponsorshipModel.fromJson(json);
      expect(spon.id, 'spon-1');
      expect(spon.amount, 420.0);
      expect(spon.status, 'PLEDGED');
    });
  });

  group('Dashboard Models Tests', () {
    test('CitizenDashboardModel parses counters and recent issues', () {
      final json = {
        'total_reported': 14,
        'verified_issues': 8,
        'in_progress_issues': 3,
        'resolved_issues': 3,
        'recent_reported_issues': [],
      };

      final dash = CitizenDashboardModel.fromJson(json);
      expect(dash.totalReported, 14);
      expect(dash.verifiedIssues, 8);
      expect(dash.inProgressIssues, 3);
      expect(dash.resolvedIssues, 3);
    });

    test('StudentDashboardModel parses counters', () {
      final json = {
        'applications_count': 5,
        'accepted_applications': 2,
        'assigned_issues': 2,
        'active_issues': 10,
        'submitted_solutions': 2,
        'selected_or_reviewed_solutions': 1,
      };

      final dash = StudentDashboardModel.fromJson(json);
      expect(dash.applicationsCount, 5);
      expect(dash.assignedIssues, 2);
      expect(dash.activeIssues, 10);
    });

    test('IndustryDashboardModel parses counters and funding', () {
      final json = {
        'issues_available_for_support': 18,
        'sponsored_issues_count': 4,
        'total_sponsored_amount': 2200.0,
        'reviewed_solutions_count': 6,
        'active_supported_projects': 3,
      };

      final dash = IndustryDashboardModel.fromJson(json);
      expect(dash.issuesAvailableForSupport, 18);
      expect(dash.sponsoredIssuesCount, 4);
      expect(dash.totalSponsoredAmount, 2200.0);
      expect(dash.activeSupportedProjects, 3);
    });
  });

  group('ApiException Tests', () {
    test('ApiException properties identify HTTP status codes', () {
      const unauthorized = ApiException(statusCode: 401, message: 'Invalid token');
      expect(unauthorized.isUnauthorized, isTrue);

      const forbidden = ApiException(statusCode: 403, message: 'Forbidden');
      expect(forbidden.isForbidden, isTrue);

      const notFound = ApiException(statusCode: 404, message: 'Not found');
      expect(notFound.isNotFound, isTrue);

      const validation = ApiException(statusCode: 422, message: 'Validation error');
      expect(validation.isValidationError, isTrue);

      const network = ApiException(statusCode: 0, message: 'No internet');
      expect(network.isNetworkError, isTrue);
    });
  });
}
