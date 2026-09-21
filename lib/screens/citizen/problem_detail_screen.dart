import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';
import '../../widgets/state_views.dart';

class ProblemDetailScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const ProblemDetailScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<ProblemDetailScreen> createState() => _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends State<ProblemDetailScreen> {
  IssueModel? _issue;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIssue();
  }

  Future<void> _loadIssue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final issueService = ServiceLocator.instance.issueService;

    try {
      if (widget.issueId != null && widget.issueId!.isNotEmpty) {
        final issue = await issueService.getIssueById(widget.issueId!);
        if (mounted) setState(() => _issue = issue);
      } else {
        final list = await issueService.listIssues(pageSize: 1);
        if (list.items.isNotEmpty) {
          if (mounted) setState(() => _issue = list.items.first);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingView(message: "Loading Problem Docket details...");
    }

    if (_errorMessage != null && _issue == null) {
      return ErrorView(
        message: "Failed to load docket: $_errorMessage",
        onRetry: _loadIssue,
      );
    }

    final issue = _issue;
    final docketId = issue != null
        ? issue.id.substring(0, 8).toUpperCase()
        : "TR-8812";
    final statusText = issue?.displayStatus ?? "UNDER EXECUTION";
    final title = issue?.title ?? "Sector 18 Road Infrastructure / Sinkhole";
    final category = issue?.displayCategory ?? "Road / Infrastructure";
    final priority = issue?.displayPriority ?? "High";
    final address = issue?.address ?? "Ward 14 • 8th Cross Arterial Junction";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onNavigate(AppView.citizenHome),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  "Docket #$docketId",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text(
            "$category • $address",
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          if (issue?.firstImageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                issue!.firstImageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // STRICT SEPARATION OF PRIORITY AND COMPLEXITY CARDS
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFFFEF2F2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CIVIC IMPACT VECTOR",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Priority: $priority",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "• Category: $category\n• Coordinates: ${issue?.latitude?.toStringAsFixed(3) ?? '28.535'}, ${issue?.longitude?.toStringAsFixed(3) ?? '77.391'}\n• Recency: Recent Active",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Card(
                  color: Color(0xFFF0F9FF),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EXECUTION LOGISTICS",
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Complexity: Med",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• Student Intervention\n• Engineering Diagnostics\n• Quality Outcome Audit\n• Verified Evidence",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text(
            "Lifecycle Milestone Audit",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _timelineStep(
            "1. Reported",
            issue?.createdAt != null
                ? "Logged by Citizen on ${issue!.createdAt!.toLocal().toString().split(' ')[0]}"
                : "Reported via Citizen Portal",
            true,
          ),
          _timelineStep(
            "2. AI Understood",
            issue?.categoryConfidence != null
                ? "Classification: ${issue?.displayCategory} (${(issue!.categoryConfidence! * 100).toInt()}% conf)"
                : "Vision model verified issue category",
            issue?.status != 'REPORTED',
          ),
          _timelineStep(
            "3. Community Verified",
            "Validated by local residents and geofence",
            issue?.status != 'REPORTED' && issue?.status != 'AI_CLASSIFIED',
          ),
          _timelineStep(
            "4. Prioritized",
            "Priority vector assessed as $priority",
            true,
          ),
          _timelineStep(
            "5. Taken up by Industrialist",
            "Industry partner allocated patronage & mentorship",
            issue?.status == 'IN_PROGRESS' ||
                issue?.status == 'SOLUTION_SUBMITTED' ||
                issue?.status == 'EVALUATED' ||
                issue?.status == 'RESOLVED',
          ),
          _timelineStep(
            "6. Students Selected",
            issue?.assignedStudentId != null
                ? "Student Assigned: #${issue!.assignedStudentId!.substring(0, 8)}"
                : "Field engineering team assignment",
            issue?.assignedStudentId != null,
          ),
          _timelineStep(
            "7. Under Execution",
            "On-site diagnostic and solution development",
            issue?.status == 'IN_PROGRESS' ||
                issue?.status == 'SOLUTION_SUBMITTED' ||
                issue?.status == 'EVALUATED' ||
                issue?.status == 'RESOLVED',
          ),
          _timelineStep(
            "8. Evidence Submitted",
            "Student EXIF photos & milestone documentation",
            issue?.status == 'SOLUTION_SUBMITTED' ||
                issue?.status == 'EVALUATED' ||
                issue?.status == 'RESOLVED',
          ),
          _timelineStep(
            "9. Outcome Verified",
            "Independent verification and audit verdict",
            issue?.status == 'RESOLVED',
          ),
        ],
      ),
    );
  }

  Widget _timelineStep(String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF006B4D) : const Color(0xFFCBD5E1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
