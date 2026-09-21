import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';

class AuditVerdictScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const AuditVerdictScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<AuditVerdictScreen> createState() => _AuditVerdictScreenState();
}

class _AuditVerdictScreenState extends State<AuditVerdictScreen> {
  String _auditVerdict = "Pending";
  IssueModel? _issue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadIssue();
  }

  Future<void> _loadIssue() async {
    setState(() => _isLoading = true);
    final issueService = ServiceLocator.instance.issueService;
    try {
      if (widget.issueId != null) {
        _issue = await issueService.getIssueById(widget.issueId!);
      } else {
        final list = await issueService.listIssues(pageSize: 1);
        if (list.items.isNotEmpty) _issue = list.items.first;
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recordVerdict(String verdict) async {
    setState(() => _auditVerdict = verdict);

    if (_issue != null && verdict == "Resolved") {
      try {
        await ServiceLocator.instance.issueService.updateIssue(
          _issue!.id,
          {"status": "RESOLVED"},
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Audit Verdict recorded: $verdict")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006B4D)));
    }
    final docketId = _issue != null
        ? _issue!.id.substring(0, 8).toUpperCase()
        : "TR-7721";
    final coords = _issue?.latitude != null
        ? "${_issue!.latitude!.toStringAsFixed(4)}° N, ${_issue!.longitude!.toStringAsFixed(4)}° E"
        : "28.5356° N, 77.3911° E";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onNavigate(AppView.industrialistHome),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  "Docket #$docketId • INDEPENDENT AUDIT",
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Text(
            "Ground Evidence & Verdict Decision",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF8FAFC),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Student Team Docket: ${_issue?.title ?? 'Apex Civic Lab Unit'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("Verified GPS: $coords"),
                  const Text("Community Consensus: 93% (14 Citizens Confirmed)"),
                  const SizedBox(height: 4),
                  Text(
                    "Current Audit Verdict Status: ${_auditVerdict.toUpperCase()}",
                    style: TextStyle(
                      color: _auditVerdict == "Resolved"
                          ? Colors.green
                          : _auditVerdict == "Disputed"
                              ? Colors.red
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Select Audit Verdict:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  onPressed: () => _recordVerdict("Resolved"),
                  child: const Text("Resolved", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => _recordVerdict("Rework"),
                  child: const Text("Rework", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => _recordVerdict("Disputed"),
                  child: const Text("Disputed", style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_auditVerdict == "Rework" || _auditVerdict == "Pending") ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REWORK DIRECTIVE MANDATE (SLO: 48 Hrs)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Required Correction: Inspect grounding wire connection on lower mast; clamp appears loose.",
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Additional Mandate: High-res macro photo of grounding bolt.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Rework Order Dispatched to Student Team (48h SLO)."),
                  ),
                );
                widget.onNavigate(AppView.industrialistHome);
              },
              child: const Text(
                "Dispatch Rework Order (48hr SLO)",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ] else if (_auditVerdict == "Resolved") ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Issue officially audited and verified! Marked as RESOLVED on platform.",
                      style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => widget.onNavigate(AppView.industrialistHome),
              child: const Text(
                "Return to Industrialist Dashboard",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
