import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/dashboard.dart';
import '../../models/issue.dart';
import '../../widgets/stat_boxes.dart';
import '../../widgets/state_views.dart';

class StudentDashboardScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final ValueChanged<String>? onSelectIssue;

  const StudentDashboardScreen({
    super.key,
    required this.onNavigate,
    this.onSelectIssue,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StudentDashboardModel? _dashboard;
  List<IssueModel> _challenges = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dashboardService = ServiceLocator.instance.dashboardService;
    final issueService = ServiceLocator.instance.issueService;

    try {
      final results = await Future.wait([
        dashboardService.getStudentDashboard().catchError((_) => const StudentDashboardModel(
              applicationsCount: 0,
              acceptedApplications: 0,
              assignedIssues: 0,
              activeIssues: 0,
              submittedSolutions: 0,
              selectedOrReviewedSolutions: 0,
            )),
        issueService.listIssues(pageSize: 10).catchError((_) => const IssueListResponse(
              total: 0,
              page: 1,
              pageSize: 10,
              items: [],
            )),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as StudentDashboardModel;
          _challenges = (results[1] as IssueListResponse).items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ServiceLocator.instance.authManager;
    final profile = auth.currentProfile;
    final studentName = profile?.name.isNotEmpty == true ? profile!.name : "Rohan Verma";
    final studentInitials = studentName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase();

    if (_isLoading) {
      return const LoadingView(message: "Loading Student Dashboard and challenges...");
    }

    if (_errorMessage != null && _dashboard == null) {
      return ErrorView(
        message: "Failed to load dashboard: $_errorMessage",
        onRetry: _loadData,
      );
    }

    final d = _dashboard;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF006B4D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0284C7),
                  child: Text(
                    studentInitials.isNotEmpty ? studentInitials : "RV",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$studentName ✓",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      profile?.location ?? "Civil & Environmental Eng. (Field Unit)",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "• Available",
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat Counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatBox(
                  value: d != null ? "${d.activeIssues > 0 ? d.activeIssues : _challenges.length}" : "${_challenges.length}",
                  label: "Available",
                ),
                StatBox(
                  value: d != null ? "${d.applicationsCount}" : "0",
                  label: "Applications",
                ),
                StatBox(
                  value: d != null ? "${d.assignedIssues}" : "0",
                  label: "Active Projects",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Challenges List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Field Challenges Available",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${_challenges.length} Issues",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_challenges.isEmpty)
              const EmptyView(
                message: "No open field challenges available right now.",
                icon: Icons.assignment_turned_in_outlined,
              )
            else
              ..._challenges.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p.displayCategory,
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              p.displayPriority,
                              style: TextStyle(
                                color: (p.priority ?? '').toUpperCase() == 'CRITICAL' ||
                                        (p.priority ?? '').toUpperCase() == 'HIGH'
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFF0F172A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p.address ?? "Ward 14 • Urban Corridor",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006B4D),
                            ),
                            onPressed: () {
                              widget.onSelectIssue?.call(p.id);
                              widget.onNavigate(AppView.studentApplication);
                            },
                            child: const Text(
                              "View Challenge & Submit Proposal",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
