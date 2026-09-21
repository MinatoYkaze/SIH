import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';

class StudentApplicationScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const StudentApplicationScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<StudentApplicationScreen> createState() =>
      _StudentApplicationScreenState();
}

class _StudentApplicationScreenState extends State<StudentApplicationScreen> {
  final _proposalController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  IssueModel? _issue;

  @override
  void initState() {
    super.initState();
    _loadIssue();
  }

  @override
  void dispose() {
    _proposalController.dispose();
    super.dispose();
  }

  Future<void> _loadIssue() async {
    if (widget.issueId == null) return;
    setState(() => _isLoading = true);
    try {
      final issue = await ServiceLocator.instance.issueService.getIssueById(widget.issueId!);
      if (mounted) setState(() => _issue = issue);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProposal() async {
    final proposal = _proposalController.text.trim();
    if (proposal.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a detailed proposal (at least 5 characters).')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final issueId = widget.issueId ?? _issue?.id;
    if (issueId == null) {
      // Demo fallback if no issue ID selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Approach Submitted to Mentor! Status: Under Review")),
      );
      widget.onNavigate(AppView.studentWorkspace);
      return;
    }

    try {
      await ServiceLocator.instance.applicationService.applyToIssue(issueId, proposal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proposal Submitted to Platform! Status: Under Review")),
        );
        widget.onNavigate(AppView.studentWorkspace);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006B4D)));
    }
    final title = _issue?.title ?? "Damaged Streetlight Cluster & Cabling";
    final category = _issue?.displayCategory ?? "Electricity & Safety";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onNavigate(AppView.studentHome),
                icon: const Icon(Icons.arrow_back),
              ),
              const Text(
                "Submit Engineering Approach",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Category: $category • Community Problem Solving",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const Divider(height: 24),
                  const Text(
                    "Proposed Technical Solution",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _proposalController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "Explain diagnostics, methodology, materials, safety protocol...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Estimated Commitment: 8-12 Hours field intervention",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B4D),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _isSubmitting ? null : _submitProposal,
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Submit Proposal to Mentor",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
