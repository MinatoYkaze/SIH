import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';

class StudentWorkspaceScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const StudentWorkspaceScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<StudentWorkspaceScreen> createState() => _StudentWorkspaceScreenState();
}

class _StudentWorkspaceScreenState extends State<StudentWorkspaceScreen> {
  IssueModel? _assignedIssue;
  bool _isLoading = false;

  final Map<int, bool> _checklist = {
    0: true,
    1: true,
    2: true,
    3: false,
  };

  @override
  void initState() {
    super.initState();
    _loadAssigned();
  }

  Future<void> _loadAssigned() async {
    setState(() => _isLoading = true);
    try {
      final assigned = await ServiceLocator.instance.issueService.getMyAssignedIssues(pageSize: 1);
      if (assigned.items.isNotEmpty) {
        if (mounted) setState(() => _assignedIssue = assigned.items.first);
      } else if (widget.issueId != null) {
        final issue = await ServiceLocator.instance.issueService.getIssueById(widget.issueId!);
        if (mounted) setState(() => _assignedIssue = issue);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006B4D)));
    }
    final issue = _assignedIssue;
    final docketId = issue != null
        ? issue.id.substring(0, 8).toUpperCase()
        : "TR-7721";
    final title = issue?.title ?? "Reconstruction of Sector 14 Conduit";
    final completedCount = _checklist.values.where((v) => v).length;
    final percent = ((completedCount / _checklist.length) * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DOCKET #$docketId",
            style: const TextStyle(
              color: Color(0xFF0284C7),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Assigned Engineering Intervention Unit",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "EXPLICIT STATUS: Your team reports that the planned intervention has been carried out.\nNotice: Not yet marked resolved. Requires objective outcome verification.",
              style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Field Intervention Checklist ($percent% Done)",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _checkItem(
            0,
            "Isolate circuit junction and secure perimeter",
            "Signed off by Team Lead",
          ),
          _checkItem(
            1,
            "Deploy replacement materials and compact sub-base",
            "Hardware spec verified",
          ),
          _checkItem(
            2,
            "Conduct safety diagnostics and IP67 weather sealing",
            "Dual gasket seated",
          ),
          _checkItem(
            3,
            "Capture geolocated photographic completion evidence",
            "Required for milestone completion",
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B4D),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => widget.onNavigate(AppView.studentEvidenceSubmit),
            child: const Text(
              "Proceed to Evidence Submission →",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(int index, String title, String detail) {
    final done = _checklist[index] ?? false;
    return Card(
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            done ? Icons.check_box : Icons.check_box_outline_blank,
            color: done ? const Color(0xFF006B4D) : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _checklist[index] = !done;
            });
          },
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : null,
            fontSize: 14,
          ),
        ),
        subtitle: Text(detail, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
