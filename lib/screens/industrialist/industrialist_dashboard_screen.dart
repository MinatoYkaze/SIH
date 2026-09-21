import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/dashboard.dart';
import '../../models/issue.dart';
import '../../widgets/stat_boxes.dart';
import '../../widgets/state_views.dart';

class IndustrialistDashboardScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final ValueChanged<String>? onSelectIssue;

  const IndustrialistDashboardScreen({
    super.key,
    required this.onNavigate,
    this.onSelectIssue,
  });

  @override
  State<IndustrialistDashboardScreen> createState() =>
      _IndustrialistDashboardScreenState();
}

class _IndustrialistDashboardScreenState
    extends State<IndustrialistDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  IndustryDashboardModel? _dashboard;
  List<IssueModel> _vettedIssues = [];

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
        dashboardService.getIndustryDashboard().catchError((_) => const IndustryDashboardModel(
              issuesAvailableForSupport: 0,
              sponsoredIssuesCount: 0,
              totalSponsoredAmount: 0.0,
              reviewedSolutionsCount: 0,
              activeSupportedProjects: 0,
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
          _dashboard = results[0] as IndustryDashboardModel;
          _vettedIssues = (results[1] as IssueListResponse).items;
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
    final name = profile?.name.isNotEmpty == true ? profile!.name : "Siddharth Singhania";
    final initials = name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase();

    if (_isLoading) {
      return const LoadingView(message: "Loading Industry Patron Hub...");
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
            // Patron Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0F172A),
                  child: Text(
                    initials.isNotEmpty ? initials : "SS",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      profile?.location ?? "VP, Apex Infra Ventures • Tier Civic Patron",
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metrics Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatBoxSmall(
                  value: "${d?.issuesAvailableForSupport ?? _vettedIssues.length}",
                  label: "Prioritized",
                ),
                StatBoxSmall(
                  value: "${d?.sponsoredIssuesCount ?? 0}",
                  label: "Sponsored",
                ),
                StatBoxSmall(
                  value: "${d?.activeSupportedProjects ?? 0}",
                  label: "Active Squads",
                ),
                StatBoxSmall(
                  value: "\$${d != null ? (d.totalSponsoredAmount).toStringAsFixed(0) : '0'}",
                  label: "Total Funding",
                ),
                StatBoxSmall(
                  value: "${d?.reviewedSolutionsCount ?? 0}",
                  label: "Evaluations",
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Vetted Civic Interventions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () => widget.onNavigate(AppView.industrialistSquadSelect),
                  child: const Text("Manage Squads"),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_vettedIssues.isEmpty)
              const EmptyView(
                message: "No vetted interventions found.",
                icon: Icons.business_center_outlined,
              )
            else
              ..._vettedIssues.map(
                (issue) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${issue.address ?? 'Ward 14'} • Status: ${issue.displayStatus}",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Category: ${issue.displayCategory} • Priority: ${issue.displayPriority}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006B4D),
                                ),
                                onPressed: () {
                                  widget.onSelectIssue?.call(issue.id);
                                  widget.onNavigate(AppView.industrialistSquadSelect);
                                },
                                child: const Text(
                                  "Take Up Problem",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                widget.onSelectIssue?.call(issue.id);
                                widget.onNavigate(AppView.industrialistLiveFeed);
                              },
                              child: const Text("Live Feed"),
                            ),
                          ],
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
