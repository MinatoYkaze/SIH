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
  bool _isSubmitting = false;
  bool _hasResponded = false;
  String? _existingResponse;

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
      final verification =
          await ServiceLocator.instance.issueService.getMyVerification(widget.issueId!);

      if (mounted) {
        setState(() {
          _issue = issue;
          _hasResponded = verification != null;
          _existingResponse = verification?['response']?.toString();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitResponse(String response) async {
    if (widget.issueId == null || _isSubmitting || _hasResponded) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await ServiceLocator.instance.issueService.verifyIssue(
        widget.issueId!,
        response,
      );

      if (!mounted) return;

      setState(() {
        _hasResponded = true;
        _existingResponse = result['response']?.toString() ?? response;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response == 'YES'
                ? "Response recorded! +15 Civic Karma"
                : "Response recorded successfully.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Response failed: $e"),
        ),
      );
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
    final title = _issue?.title ?? "Severe Asphalt Pothole near Pillar 42";
    final category = _issue?.displayCategory ?? "Road Infrastructure";
    final priority = _issue?.displayPriority ?? "High";
    final docketId = _issue?.id.isNotEmpty == true
        ? _issue!.id.substring(0, 8).toUpperCase()
        : "Issue";

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

          if (_hasResponded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _existingResponse == 'YES'
                          ? "Already Responded: Yes, it still exists"
                          : "Already Responded: No, it appears resolved",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => _submitResponse('YES'),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
              label: Text(
                _isSubmitting
                    ? "Recording response..."
                    : "Yes, it still exists",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => _submitResponse('NO'),
              icon: const Icon(Icons.close),
              label: const Text("No, it appears resolved"),
            ),
          ],

          const SizedBox(height: 8),
          TextButton(
            onPressed: () => widget.onNavigate(AppView.citizenHome),
            child: const Center(
              child: Text("Not sure / Can't see clearly"),
            ),
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
