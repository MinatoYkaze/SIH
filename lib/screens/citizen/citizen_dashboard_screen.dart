import '../../models/points.dart';
import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/dashboard.dart';
import '../../models/issue.dart';
import '../../widgets/state_views.dart';

class CitizenDashboardScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final ValueChanged<String>? onSelectIssue;

  const CitizenDashboardScreen({
    super.key,
    required this.onNavigate,
    this.onSelectIssue,
  });

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  CitizenDashboardModel? _dashboard;
  List<IssueModel> _myReportedIssues = [];
  List<IssueModel> _nearbyIssues = [];
  String _activeFilter = 'All';
  PointsModel? _points;

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
    final pointsService = ServiceLocator.instance.pointsService;

    try {
      final results = await Future.wait([
        dashboardService.getCitizenDashboard().catchError((_) => const CitizenDashboardModel(
              totalReported: 0,
              verifiedIssues: 0,
              inProgressIssues: 0,
              resolvedIssues: 0,
            )),
        issueService.getMyReportedIssues(pageSize: 5).catchError((_) => const IssueListResponse(
              total: 0,
              page: 1,
              pageSize: 5,
              items: [],
            )),
        issueService.listIssues(pageSize: 10).catchError((_) => const IssueListResponse(
              total: 0,
              page: 1,
              pageSize: 10,
              items: [],
            )),
        pointsService.getMyPoints(),
      ]);

      if (mounted) {
        setState(() {
          _dashboard = results[0] as CitizenDashboardModel;
          _myReportedIssues = (results[1] as IssueListResponse).items;
          _nearbyIssues = (results[2] as IssueListResponse).items;
          _points = results[3] as PointsModel;
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

  List<IssueModel> get _filteredIssues {
    if (_activeFilter == 'High priority') {
      return _nearbyIssues.where((i) => (i.priority ?? '').toUpperCase() == 'HIGH' || (i.priority ?? '').toUpperCase() == 'CRITICAL').toList();
    }
    if (_activeFilter == 'Unverified') {
      return _nearbyIssues.where((i) => i.status == 'REPORTED' || i.status == 'AI_CLASSIFIED').toList();
    }
    if (_activeFilter == 'Still active') {
      return _nearbyIssues.where((i) => i.status != 'RESOLVED').toList();
    }
    return _nearbyIssues;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ServiceLocator.instance.authManager;
    final profile = auth.currentProfile;
    final displayName = profile?.name.isNotEmpty == true ? profile!.name : 'Citizen Watch';
    final locationLabel = profile?.location?.isNotEmpty == true ? profile!.location! : 'Sector 18, Metro Corridor ▾';

    if (_isLoading) {
      return const LoadingView(message: 'Loading Citizen Dashboard and reports...');
    }

    if (_errorMessage != null && _dashboard == null) {
      return ErrorView(
        message: 'Failed to load dashboard: $_errorMessage',
        onRetry: _loadData,
      );
    }

    final initials = displayName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF006B4D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF006B4D),
                  child: Text(
                    initials.isNotEmpty ? initials : "CW",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $displayName",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      locationLabel,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_points != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B4D),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Karma Points',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your civic contribution',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${_points!.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search nearby problems, roads, water...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                // Filter nearby issues by title/category
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _nearbyIssues = _nearbyIssues
                        .where((i) =>
                            i.title.toLowerCase().contains(val.toLowerCase()) ||
                            (i.category ?? '').toLowerCase().contains(val.toLowerCase()))
                        .toList();
                  });
                } else {
                  _loadData();
                }
              },
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip("All (${_nearbyIssues.length})", _activeFilter == 'All', () => setState(() => _activeFilter = 'All')),
                  _chip("High priority", _activeFilter == 'High priority', () => setState(() => _activeFilter = 'High priority')),
                  _chip("Unverified", _activeFilter == 'Unverified', () => setState(() => _activeFilter = 'Unverified')),
                  _chip("Still active", _activeFilter == 'Still active', () => setState(() => _activeFilter = 'Still active')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map Preview / Ops Banner
            InkWell(
              onTap: _nearbyIssues.isEmpty
                  ? null
                  : () {
                      final issue = _nearbyIssues.first;
                      widget.onSelectIssue?.call(issue.id);
                      widget.onNavigate(AppView.problemDetailView);
                    },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, color: Color(0xFF006B4D), size: 36),
                          const SizedBox(height: 4),
                          const Text(
                            "Interactive GIS Map & Operations",
                            style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${_nearbyIssues.length} active civic issues geo-tagged",
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_nearbyIssues.isNotEmpty) ...[
                      Positioned(
                        top: 25,
                        left: 30,
                        child: _mapPin(Icons.warning, Colors.red, _nearbyIssues[0].category ?? "Road Issue"),
                      ),
                    ],
                    if (_nearbyIssues.length > 1) ...[
                      Positioned(
                        top: 60,
                        right: 40,
                        child: _mapPin(Icons.water_drop, Colors.blue, _nearbyIssues[1].category ?? "Pipeline"),
                      ),
                    ],
                    if (_nearbyIssues.length > 2) ...[
                      Positioned(
                        bottom: 25,
                        left: 90,
                        child: _mapPin(Icons.delete, Colors.green, _nearbyIssues[2].category ?? "Sanitation"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Primary Action Button: Report a Problem
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => widget.onNavigate(AppView.citizenReportWizard),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  "Report a Problem",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Dashboard Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Action Dashboard",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_dashboard != null)
                  Text(
                    "Total: ${_dashboard!.totalReported} | Resolved: ${_dashboard!.resolvedIssues}",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF006B4D), fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // My Reported Issues List
            if (_myReportedIssues.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF64748B)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No reported issues yet. Tap 'Report a Problem' to document a civic concern.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._myReportedIssues.map(
                (issue) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Color(0xFF006B4D)),
                    title: Text(
                      issue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      "${issue.displayStatus} • ${issue.displayCategory}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFECFDF5)),
                      onPressed: () {
                        widget.onSelectIssue?.call(issue.id);
                        widget.onNavigate(AppView.problemDetailView);
                      },
                      child: const Text(
                        "Track",
                        style: TextStyle(color: Color(0xFF006B4D), fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),

            // Nearby Verification Prompt Card
            if (_filteredIssues.isNotEmpty) ...[
              const SizedBox(height: 4),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.near_me, color: Color(0xFF0284C7)),
                  title: Text(
                    _filteredIssues.first.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    "${_filteredIssues.first.address ?? 'Nearby problem'} • Needs Verification",
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: () {
                      widget.onSelectIssue?.call(_filteredIssues.first.id);
                      widget.onNavigate(AppView.citizenGeofenceCheck);
                    },
                    child: const Text(
                      "Verify",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _mapPin(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: Colors.white70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
