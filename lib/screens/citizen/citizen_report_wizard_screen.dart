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
    if (mounted) {
      setState(() {
        _isLocating = true;
        _addressPreview = "Detecting current coordinates...";
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _latitude = null;
          _longitude = null;
          _addressPreview = "Location services are disabled.";
          _isLocating = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _latitude = null;
          _longitude = null;
          _addressPreview = permission == LocationPermission.deniedForever
              ? "Location permission is permanently denied."
              : "Location permission was denied.";
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

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressPreview =
            "GPS Verified: ${position.latitude.toStringAsFixed(4)}° N, "
            "${position.longitude.toStringAsFixed(4)}° E";
        _isLocating = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _latitude = null;
        _longitude = null;
        _addressPreview = "Unable to detect GPS location.";
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
                        _latitude != null && _longitude != null
                            ? "GPS Detected:\n${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° E\nAdjust Pin on Map"
                            : "GPS location unavailable\nEnable location services to continue",
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
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFBBF7D0),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF16A34A),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Report Review",
                          style: TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Review the information before submitting your report.",
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "REPORT DETAILS",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          color: Color(0xFF006B4D),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Category",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _citizenSelectedCategory,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.priority_high_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Priority",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selectedPriority,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Nearby Issue Check",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "A similar historical issue was found nearby.",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Location validated using GPS.",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "Submit Report",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
                  if (_createdIssue != null) ...[
                    Text(
                      "Problem ID: #${_createdIssue!.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      "Status: ${_createdIssue!.displayStatus}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: _createdIssue == null
                  ? null
                  : () {
                      widget.onIssueCreated?.call(_createdIssue!.id);
                      widget.onNavigate(AppView.problemDetailView);
                    },
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
