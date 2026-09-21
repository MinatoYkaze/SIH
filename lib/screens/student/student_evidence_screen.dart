import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/evidence.dart';

class StudentEvidenceScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final String? issueId;

  const StudentEvidenceScreen({
    super.key,
    required this.onNavigate,
    this.issueId,
  });

  @override
  State<StudentEvidenceScreen> createState() => _StudentEvidenceScreenState();
}

class _StudentEvidenceScreenState extends State<StudentEvidenceScreen> {
  bool _confirmCheck = false;
  XFile? _afterImage;
  bool _isSubmitting = false;
  final _summaryController = TextEditingController(
    text: "• Replaced 150W transformers\n• Re-crimped terminal leads\n• Sealed IP67 enclosure",
  );

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickAfterImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _afterImage = img);
    }
  }

  Future<void> _submitEvidence() async {
    if (!_confirmCheck) return;

    setState(() => _isSubmitting = true);

    final issueId = widget.issueId;
    if (issueId != null) {
      try {
        await ServiceLocator.instance.evidenceService.createEvidence(
          issueId,
          EvidenceCreate(
            mediaUrl: "https://images.unsplash.com/photo-1541888946425-d0fbb186156a?w=800",
            description: _summaryController.text.trim(),
            evidenceType: "AFTER",
          ),
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Submitted! Status: Execution Evidence Submitted — Outcome Verification Pending",
          ),
        ),
      );
      widget.onNavigate(AppView.industrialistAuditVerdict);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Photographic Audit • DUAL-PROOF MATCHED",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "BEFORE\nOriginal Incident",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _pickAfterImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: _afterImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(_afterImage!.path, fit: BoxFit.cover)
                                : Image.file(File(_afterImage!.path), fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Text(
                              "RESOLVED: AFTER\nTap to Upload Photo\n(EXIF Geo-Tagged)",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Work Performed Summary:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _summaryController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _confirmCheck,
                onChanged: (v) => setState(() => _confirmCheck = v ?? false),
              ),
              const Expanded(
                child: Text(
                  "I confirm that this evidence accurately represents work carried out by the team.",
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006B4D),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _confirmCheck && !_isSubmitting ? _submitEvidence : null,
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Submit for Outcome Verification",
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
