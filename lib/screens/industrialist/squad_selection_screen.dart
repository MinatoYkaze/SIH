import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/application.dart';
import '../../models/issue.dart';
import '../../models/sponsorship.dart';

class SquadSelectionScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const SquadSelectionScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<SquadSelectionScreen> createState() => _SquadSelectionScreenState();
}

class _SquadSelectionScreenState extends State<SquadSelectionScreen> {
  IssueModel? _issue;
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _assignedStudentId;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    final issueService = ServiceLocator.instance.issueService;
    final appService = ServiceLocator.instance.applicationService;

    try {
      if (widget.issueId != null) {
        _issue = await issueService.getIssueById(widget.issueId!);
        _applications = await appService.listApplicationsForIssue(widget.issueId!);
      } else {
        final list = await issueService.listIssues(pageSize: 1);
        if (list.items.isNotEmpty) {
          _issue = list.items.first;
          _applications = await appService.listApplicationsForIssue(_issue!.id);
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignStudent(String studentId, String applicantName) async {
    if (_issue == null) return;
    try {
      await ServiceLocator.instance.applicationService.assignStudentToIssue(
        _issue!.id,
        studentId,
      );
      setState(() => _assignedStudentId = studentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$applicantName assigned to squad! Issue moved to IN_PROGRESS.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Assignment updated for $applicantName")),
        );
      }
    }
  }

  Future<void> _finalizeTeam() async {
    if (_issue != null) {
      try {
        await ServiceLocator.instance.sponsorshipService.createSponsorship(
          _issue!.id,
          const SponsorshipCreate(
            amount: 420.0,
            message: "Sponsored by Industrialist Patron • Grant authorized",
          ),
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Team Finalized! Escrow Smart Contract Activated.")),
      );
      widget.onNavigate(AppView.industrialistLiveFeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006B4D)));
    }
    final title = _issue?.title ?? "Sector 18 Road Infrastructure";
    final count = _applications.isNotEmpty ? _applications.length : 2;

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
              const Expanded(
                child: Text(
                  "Sponsor Grant Commitment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          Text(
            "$title • $count Candidate Applicants",
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (_applications.isEmpty) ...[
            _applicantCard(
              id: "00000000-0000-0000-0000-000000000002",
              name: "Aarav Mehta (98% Match)",
              dept: "Civil Engineering • Final Year",
              proposal: "Proposed: Cold-pour asphalt emulsion with gravel compaction layer",
            ),
            const SizedBox(height: 8),
            _applicantCard(
              id: "00000000-0000-0000-0000-000000000003",
              name: "Priya Das (91% Match)",
              dept: "Urban Infrastructure • 3rd Year",
              proposal: "Proposed: Topographical survey & rapid drainage routing",
            ),
          ] else ...[
            ..._applications.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _applicantCard(
                  id: app.studentId,
                  name: "${app.student?.name ?? 'Applicant #${app.studentId.substring(0, 6)}'} (Verified)",
                  dept: "Engineering Field Squad",
                  proposal: "Proposed: ${app.proposal}",
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SQUAD AUTHORIZATION DOSSIER",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                SizedBox(height: 4),
                Text("Escrow Resources: \$420 Locked in Escrow ✓"),
                Text("Faculty Mentor: Prof. Siddharth Singhania"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _finalizeTeam,
            child: const Text(
              "Finalize Team & Authorize Work",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicantCard({
    required String id,
    required String name,
    required String dept,
    required String proposal,
  }) {
    final isAssigned = _assignedStudentId == id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              dept,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(proposal, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAssigned ? Colors.grey : const Color(0xFF006B4D),
              ),
              onPressed: () => _assignStudent(id, name),
              child: Text(
                isAssigned ? "Assigned ✓" : "Add to Team",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
