import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';

class CitizenGeofenceScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const CitizenGeofenceScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<CitizenGeofenceScreen> createState() => _CitizenGeofenceScreenState();
}

class _CitizenGeofenceScreenState extends State<CitizenGeofenceScreen> {
  IssueModel? _issue;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchIssue();
  }

  Future<void> _fetchIssue() async {
    if (widget.issueId == null) return;
    setState(() => _isLoading = true);
    try {
      final issue = await ServiceLocator.instance.issueService.getIssueById(widget.issueId!);
      if (mounted) setState(() => _issue = issue);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF006B4D)));
    }
    final title = _issue?.title ?? "Severe Asphalt Pothole near Pillar 42";
    final category = _issue?.displayCategory ?? "Road Infrastructure";
    final priority = _issue?.displayPriority ?? "High";
    final docketId = _issue != null ? _issue!.id.substring(0, 8).toUpperCase() : "TR-8812";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "GEOFENCE TRIGGERED: You are within 60m of a reported civic problem",
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "#$docketId • Category: $category • Priority: $priority",
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          const Text(
            "Can you confirm whether this problem still exists?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B4D),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Verification recorded! +15 Civic Karma")),
              );
              widget.onNavigate(AppView.citizenHome);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Yes, it still exists",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Feedback submitted for outcome review.")),
              );
              widget.onNavigate(AppView.citizenHome);
            },
            icon: const Icon(Icons.close),
            label: const Text("No, it appears resolved"),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => widget.onNavigate(AppView.citizenHome),
            child: const Center(child: Text("Not sure / Can't see clearly")),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "ROLE PROTOCOL DISTINCTION:\nCitizens provide community verification evidence. Students submit official engineering completion evidence.",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
