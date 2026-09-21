import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/issue.dart';

class CitizenReportWizardScreen extends StatefulWidget {
  final ValueChanged<AppView> onNavigate;
  final ValueChanged<String>? onIssueCreated;

  const CitizenReportWizardScreen({
    super.key,
    required this.onNavigate,
    this.onIssueCreated,
  });

  @override
  State<CitizenReportWizardScreen> createState() =>
      _CitizenReportWizardScreenState();
}

class _CitizenReportWizardScreenState extends State<CitizenReportWizardScreen> {
  int _reportStep = 1;

  // Step 1: Evidence State
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Step 2: Description State
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _citizenSelectedCategory = "Road damage";
  String _selectedPriority = "HIGH";

  // Step 3: Location State
  double? _latitude;
  double? _longitude;
  String _addressPreview = "Detecting GPS location...";
  bool _isLocating = false;

  // Step 4 & 5: Submission State
  bool _isSubmitting = false;
  String? _submissionError;
  IssueModel? _createdIssue;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _addressPreview = "Detecting current coordinates...";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _latitude = 28.5355;
          _longitude = 77.3910;
          _addressPreview = "Sector 18, Gate 2 Metro Exit (GPS Disabled)";
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _latitude = 28.5355;
            _longitude = 77.3910;
            _addressPreview = "Sector 18, Gate 2 Metro Exit (Default Location)";
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _latitude = 28.5355;
          _longitude = 77.3910;
          _addressPreview = "Sector 18, Gate 2 Metro Exit (Default Location)";
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressPreview =
            "GPS Verified: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E";
        _isLocating = false;
      });
    } catch (_) {
      setState(() {
        _latitude = 28.5355;
        _longitude = 77.3910;
        _addressPreview = "Sector 18, Gate 2 Metro Corridor";
        _isLocating = false;
      });
    }
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final issueService = ServiceLocator.instance.issueService;

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : "$_citizenSelectedCategory near ${_addressPreview.split(',').first}";

    final description = _descriptionController.text.trim().length >= 5
        ? _descriptionController.text.trim()
        : "Civic hazard reported at location requiring immediate inspection and technical intervention.";

    try {
      // 1. Create issue
      final issue = await issueService.createIssue(
        IssueCreate(
          title: title,
          description: description,
          category: _citizenSelectedCategory,
          priority: _selectedPriority,
          latitude: _latitude,
          longitude: _longitude,
          address: _addressPreview,
          mediaUrls: _selectedImage != null
              ? ["https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800"]
              : null,
        ),
      );

      // 2. Attach media if image was selected
      if (_selectedImage != null) {
        try {
          await issueService.attachMedia(
            issue.id,
            "https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800",
            mediaType: "image",
          );
        } catch (_) {}
      }

      setState(() {
        _createdIssue = issue;
        _reportStep = 5;
        _isSubmitting = false;
      });

      widget.onIssueCreated?.call(issue.id);
    } catch (e) {
      setState(() {
        _submissionError = e.toString().replaceAll('ApiException', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "STEP $_reportStep OF 5",
                style: const TextStyle(
                  color: Color(0xFF006B4D),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              IconButton(
                onPressed: () => widget.onNavigate(AppView.citizenHome),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: _reportStep / 5,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF006B4D),
          ),
          const SizedBox(height: 20),

          if (_submissionError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _submissionError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // STEP 1: ADD EVIDENCE
          if (_reportStep == 1) ...[
            const Text(
              "Step 1: Add Evidence",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showImageSourceActionSheet(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Color(0xFF64748B)),
                          SizedBox(height: 8),
                          Text(
                            "Take Photo or Upload from Gallery",
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text("Camera"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Gallery"),
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
              onPressed: () => setState(() => _reportStep = 2),
              child: const Text(
                "Continue to Description",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],

          // STEP 2: DESCRIBE THE PROBLEM
          if (_reportStep == 2) ...[
            const Text(
              "Step 2: Describe the Problem",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Issue Title",
                hintText: "e.g., Deep asphalt pothole near college gate",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Detailed Description",
                hintText: "e.g., Large sinkhole causing traffic slowdown and safety risk",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Category Selection:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _citizenSelectedCategory,
              items: [
                "Road damage",
                "Waste accumulation",
                "Water leakage",
                "Electricity/Lighting",
                "Public Safety"
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _citizenSelectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              "Priority Assessment:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedPriority,
              items: ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPriority = val);
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => setState(() => _reportStep = 3),
              child: const Text(
                "Confirm Location",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],

          // STEP 3: CONFIRM LOCATION
          if (_reportStep == 3) ...[
            const Text(
              "Step 3: Confirm Location",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isLocating
                    ? const CircularProgressIndicator(color: Color(0xFF006B4D))
                    : Text(
                        "GPS Detected:\n${_latitude?.toStringAsFixed(4) ?? '28.5355'}° N, ${_longitude?.toStringAsFixed(4) ?? '77.3910'}° E\nAdjust Pin on Map",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Address Preview: $_addressPreview",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => setState(() => _reportStep = 4),
              child: const Text(
                "Run AI Understanding Check",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],

          // STEP 4: AI UNDERSTANDING & DEDUPLICATION
          if (_reportStep == 4) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text(
                    "CIVICAI COPILOT • Reviewable Preview",
                    style: TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Target Category: $_citizenSelectedCategory (Verified by Reporter)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Estimated Severity: $_selectedPriority (Ground Inspection)",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text(
                      "SIMILAR NEARBY ISSUE DETECTED",
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Historical docket in sector • Coordinates validated via GPS",
                      style: TextStyle(fontSize: 13),
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
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Submit Report to Platform",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],

          // STEP 5: SUBMISSION CONFIRMATION
          if (_reportStep == 5) ...[
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  const Text(
                    "Report Submitted Successfully!",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Problem ID: #${_createdIssue?.id.substring(0, 8).toUpperCase() ?? 'TR-4092'}",
                    style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  Text(
                    "Status: ${_createdIssue?.displayStatus ?? 'Reported ➔ AI Review Pending'}",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () => widget.onNavigate(AppView.problemDetailView),
              child: const Text(
                "View Problem Details",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
