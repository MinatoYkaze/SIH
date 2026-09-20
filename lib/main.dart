import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TransitionApp());
}

// ==========================================
// DATA MODELS & ENUMS
// ==========================================
enum UserRole { landing, roleSelect, citizen, student, industrialist }

enum AppView {
  landing,
  roleSelect,
  // Citizen Views
  citizenHome,
  citizenReportWizard,
  citizenGeofenceCheck,
  problemDetailView,
  // Student Views
  studentHome,
  studentApplication,
  studentWorkspace,
  studentEvidenceSubmit,
  // Industrialist Views
  industrialistHome,
  industrialistSquadSelect,
  industrialistLiveFeed,
  industrialistAuditVerdict,
}

class ProblemItem {
  final String id;
  final String title;
  final String category;
  final String location;
  final String priorityLabel;
  final int priorityScore;
  final String complexityLabel;
  final int complexityScore;
  final int commutersAffected;
  final String supportRequired;
  final String requiredSkills;
  final String currentStage;
  final String sponsorName;

  ProblemItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.priorityLabel,
    required this.priorityScore,
    required this.complexityLabel,
    required this.complexityScore,
    required this.commutersAffected,
    required this.supportRequired,
    required this.requiredSkills,
    required this.currentStage,
    required this.sponsorName,
  });
}

/// Small API client for the deployed SIH backend. Pass an authenticated token
/// when building the app: --dart-define=SIH_API_TOKEN=<your JWT>.
class SihApi {
  static const String baseUrl = 'https://sih-a24k.onrender.com';
  static const String token = String.fromEnvironment('SIH_API_TOKEN');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  ProblemItem _toProblem(Map<String, dynamic> issue) => ProblemItem(
        id: '${issue['id'] ?? 'NEW'}',
        title: '${issue['title'] ?? 'Untitled issue'}',
        category: '${issue['category'] ?? 'Civic issue'}',
        location: '${issue['address'] ?? 'Location unavailable'}',
        priorityLabel: '${issue['priority'] ?? 'Normal'}',
        priorityScore: 0,
        complexityLabel: 'Awaiting assessment',
        complexityScore: 0,
        commutersAffected: 0,
        supportRequired: 'Assessment pending',
        requiredSkills: 'To be assigned',
        currentStage: '${issue['status'] ?? 'Reported'}',
        sponsorName: 'Unassigned',
      );

  Future<List<ProblemItem>> listIssues() async {
    final response = await http.get(Uri.parse('$baseUrl/issues'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load issues (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    final items = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['items'] ?? decoded['issues'] ?? [] : []);
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((raw) => _toProblem(Map<String, dynamic>.from(raw)))
        .toList();
  }

  Future<ProblemItem> createIssue({
    required String title,
    required String category,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/issues'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': title,
        'category': category,
        'priority': 'LOW',
        'latitude': 28.5355,
        'longitude': 77.3910,
        'address': 'Sector 18, Gate 2 Metro Exit',
        'media_urls': [],
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = response.body.isEmpty ? '' : ': ${response.body}';
      throw Exception('Report could not be submitted (${response.statusCode})$detail');
    }
    final issue = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return _toProblem(issue);
  }
}

// ==========================================
// MAIN APPLICATION ENTRY POINT
// ==========================================
class TransitionApp extends StatefulWidget {
  const TransitionApp({super.key});

  @override
  State<TransitionApp> createState() => _TransitionAppState();
}

class _TransitionAppState extends State<TransitionApp> {
  UserRole _currentRole = UserRole.landing;
  AppView _currentView = AppView.landing;

  // Global Mock State
  final List<ProblemItem> _problems = [
    ProblemItem(
      id: "TR-8812",
      title: "Sector 18 Road Infrastructure / Sinkhole",
      category: "Road / Infrastructure",
      location: "Ward 14 • 8th Cross Arterial Junction",
      priorityLabel: "High",
      priorityScore: 92,
      complexityLabel: "Medium",
      complexityScore: 58,
      commutersAffected: 1450,
      supportRequired: "\$420 Capital + Bitumen Compactor",
      requiredSkills: "Civil Engineering, Asphalt Testing",
      currentStage: "Under Execution",
      sponsorName: "Apex Infra Ventures",
    ),
    ProblemItem(
      id: "TR-7721",
      title: "Damaged Streetlight Cluster & Cabling",
      category: "Electricity & Safety",
      location: "Sector 14 Crossroad Grid Sub-station",
      priorityLabel: "Critical",
      priorityScore: 850,
      complexityLabel: "Feasible",
      complexityScore: 45,
      commutersAffected: 850,
      supportRequired: "\$350 Parts Budget + Testing Gear",
      requiredSkills: "Multimeter Diagnostics, IP67 Sealing",
      currentStage: "Industrialist Sponsored",
      sponsorName: "Apex Energy Labs",
    ),
  ];

  int _reportStep = 1;
  String _citizenSelectedCategory = "Road damage";
  bool _confirmCheck = false;
  String _auditVerdict = "Pending";
  final SihApi _api = SihApi();
  final TextEditingController _reportTitleController = TextEditingController();
  List<ProblemItem> _apiProblems = [];
  bool _issuesLoading = false;
  String? _issuesError;
  String? _submittedIssueId;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  @override
  void dispose() {
    _reportTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    setState(() {
      _issuesLoading = true;
      _issuesError = null;
    });
    try {
      final issues = await _api.listIssues();
      if (mounted) {
        setState(() => _apiProblems = issues);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _issuesError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _issuesLoading = false);
      }
    }
  }

  Future<void> _submitIssue() async {
    final title = _reportTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a short problem description first.')),
      );
      return;
    }
    try {
      final issue = await _api.createIssue(
        title: title,
        category: _citizenSelectedCategory,
      );
      if (!mounted) return;
      setState(() {
        _submittedIssueId = issue.id;
        _apiProblems = [issue, ..._apiProblems];
        _reportStep = 5;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _navigateTo(AppView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _switchRole(UserRole role) {
    setState(() {
      _currentRole = role;
      switch (role) {
        case UserRole.landing:
          _currentView = AppView.landing;
          break;
        case UserRole.roleSelect:
          _currentView = AppView.roleSelect;
          break;
        case UserRole.citizen:
          _currentView = AppView.citizenHome;
          break;
        case UserRole.student:
          _currentView = AppView.studentHome;
          break;
        case UserRole.industrialist:
          _currentView = AppView.industrialistHome;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRANSITION Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        primaryColor: const Color(0xFF006B4D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006B4D),
          primary: const Color(0xFF006B4D),
          secondary: const Color(0xFF0F172A),
        ),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildGlobalTopBar(),
              Expanded(child: _buildBody()),
              if (_currentRole != UserRole.landing &&
                  _currentRole != UserRole.roleSelect)
                _buildRoleNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  // Header switcher for rapid testing across all portals
  Widget _buildGlobalTopBar() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.hub, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 8),
          const Text(
            "TRANSITION",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1),
          ),
          const Spacer(),
          DropdownButton<UserRole>(
            dropdownColor: const Color(0xFF1E293B),
            value: _currentRole,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: const [
              DropdownMenuItem(
                  value: UserRole.landing,
                  child: Text("Welcome Screen",
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: UserRole.roleSelect,
                  child: Text("Role Selection",
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: UserRole.citizen,
                  child: Text("Citizen Portal",
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: UserRole.student,
                  child: Text("Student Portal",
                      style: TextStyle(color: Colors.white))),
              DropdownMenuItem(
                  value: UserRole.industrialist,
                  child: Text("Industrialist Hub",
                      style: TextStyle(color: Colors.white))),
            ],
            onChanged: (role) {
              if (role != null) _switchRole(role);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case AppView.landing:
        return _buildLandingView();
      case AppView.roleSelect:
        return _buildRoleSelectionView();
      // Citizen Views
      case AppView.citizenHome:
        return _buildCitizenDashboard();
      case AppView.citizenReportWizard:
        return _buildCitizenReportWizard();
      case AppView.citizenGeofenceCheck:
        return _buildCitizenGeofencePrompt();
      case AppView.problemDetailView:
        return _buildProblemDetailView();
      // Student Views
      case AppView.studentHome:
        return _buildStudentDashboard();
      case AppView.studentApplication:
        return _buildStudentApplicationView();
      case AppView.studentWorkspace:
        return _buildStudentWorkspaceView();
      case AppView.studentEvidenceSubmit:
        return _buildStudentEvidenceSubmissionView();
      // Industrialist Views
      case AppView.industrialistHome:
        return _buildIndustrialistDashboard();
      case AppView.industrialistSquadSelect:
        return _buildIndustrialistSquadSelectionView();
      case AppView.industrialistLiveFeed:
        return _buildIndustrialistLiveFeedView();
      case AppView.industrialistAuditVerdict:
        return _buildIndustrialistAuditVerdictView();
    }
  }

  // Nav bar mirroring role navigation
  Widget _buildRoleNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", () {
            if (_currentRole == UserRole.citizen) {
              _navigateTo(AppView.citizenHome);
            }
            if (_currentRole == UserRole.student) {
              _navigateTo(AppView.studentHome);
            }
            if (_currentRole == UserRole.industrialist) {
              _navigateTo(AppView.industrialistHome);
            }
          }),
          _navItem(Icons.map, "Map/Ops",
              () => _navigateTo(AppView.problemDetailView)),
          if (_currentRole == UserRole.citizen)
            _navItem(Icons.add_circle, "Report",
                () => _navigateTo(AppView.citizenReportWizard)),
          if (_currentRole == UserRole.student)
            _navItem(Icons.build, "Workspace",
                () => _navigateTo(AppView.studentWorkspace)),
          if (_currentRole == UserRole.industrialist)
            _navItem(Icons.groups, "Squads",
                () => _navigateTo(AppView.industrialistSquadSelect)),
          _navItem(Icons.verified, "Audit", () {
            if (_currentRole == UserRole.industrialist) {
              _navigateTo(AppView.industrialistAuditVerdict);
            }
            if (_currentRole == UserRole.citizen) {
              _navigateTo(AppView.citizenGeofenceCheck);
            }
            if (_currentRole == UserRole.student) {
              _navigateTo(AppView.studentEvidenceSubmit);
            }
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF006B4D), size: 22),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 1: WELCOME / LANDING PAGE
  // ==========================================
  Widget _buildLandingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "• CIVIC TECH MOVEMENT",
              style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "From civic reporting to real-world action.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Report verified local problems, connect them with industrialist mentors, and enable students to execute practical interventions.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Interactive Action Engine Illustration Node
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text("The Civic Action Engine",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _nodeChip("Citizen", "Reports & Verifies",
                        const Color(0xFF10B981)),
                    const Icon(Icons.arrow_forward, color: Color(0xFF94A3B8)),
                    _nodeChip("Industrialist", "Mentors & Funds",
                        const Color(0xFF0F172A)),
                  ],
                ),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_downward, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                _nodeChip(
                    "Student Unit", "Executes Work", const Color(0xFF0284C7)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBox(value: "8.4k", label: "ISSUES LOGGED"),
              _StatBox(value: "94%", label: "RESOLVED RATE"),
              _StatBox(value: "320+", label: "CAMPUS TEAMS"),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _switchRole(UserRole.roleSelect),
              child: const Text("Get Started →",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text("How TRANSITION Works",
                style: TextStyle(color: Color(0xFF006B4D))),
          ),
        ],
      ),
    );
  }

  Widget _nodeChip(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 2: ROLE SELECTION
  // ==========================================
  Widget _buildRoleSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("02 STEP 2 OF 3",
              style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(height: 4),
          const Text("Choose Your Role",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text(
              "The role selection customizes your civic dashboard and active toolsets.",
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          _roleCard(
            role: UserRole.citizen,
            title: "Citizen",
            badge: "Ground Team",
            description: "Community Watch & Local Verification",
            bullets: [
              "Report civic problems",
              "Verify nearby issues",
              "Track outcomes"
            ],
            buttonLabel: "Select Citizen",
          ),
          const SizedBox(height: 16),
          _roleCard(
            role: UserRole.student,
            title: "Student",
            badge: "Field Unit",
            description: "Hands-on Engineering & Civic Execution",
            bullets: [
              "Discover problems",
              "Join intervention teams",
              "Submit execution evidence"
            ],
            buttonLabel: "Select Student",
          ),
          const SizedBox(height: 16),
          _roleCard(
            role: UserRole.industrialist,
            title: "Industrialist",
            badge: "Sponsor & Mentor",
            description: "Mentorship, Capital & Resources",
            bullets: [
              "Take up prioritized problems",
              "Select and mentor students",
              "Support practical solutions"
            ],
            buttonLabel: "Select Industrialist",
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required UserRole role,
    required String title,
    required String badge,
    required String description,
    required List<String> bullets,
    required String buttonLabel,
  }) {
    final bool isSelected = _currentRole == role;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isSelected ? const Color(0xFF006B4D) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(badge,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(b, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF006B4D)
                        : const Color(0xFFCBD5E1)),
                backgroundColor:
                    isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
              ),
              onPressed: () => _switchRole(role),
              child: Text(buttonLabel,
                  style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF006B4D)
                          : const Color(0xFF0F172A))),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 3: CITIZEN DASHBOARD
  // ==========================================
  Widget _buildCitizenDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const CircleAvatar(
                  backgroundColor: Color(0xFF006B4D),
                  child: Text("AS", style: TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, Aarav Sharma",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Sector 18, Metro Corridor ▾",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {}, icon: const Icon(Icons.notifications_none)),
            ],
          ),
          const SizedBox(height: 16),
          // Search & Filters
          TextField(
            decoration: InputDecoration(
              hintText: "Search nearby problems, roads, water...",
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip("Nearby (8)", true),
                _chip("High priority (3)", false),
                _chip("Unverified (4)", false),
                _chip("Still active", false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Map Placeholder Visual with Category Pins
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                const Center(
                    child: Text("Interactive GIS Map Visual",
                        style: TextStyle(color: Color(0xFF64748B)))),
                Positioned(
                  top: 30,
                  left: 40,
                  child: _mapPin(Icons.warning, Colors.red, "Pothole crater"),
                ),
                Positioned(
                  top: 70,
                  right: 50,
                  child:
                      _mapPin(Icons.water_drop, Colors.blue, "Burst pipeline"),
                ),
                Positioned(
                  bottom: 30,
                  left: 100,
                  child: _mapPin(Icons.delete, Colors.green, "Garbage dump"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Primary Action Floating Trigger
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() => _reportStep = 1);
                _navigateTo(AppView.citizenReportWizard);
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text("Report a Problem",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined, size: 16, color: Color(0xFF006B4D)),
              const SizedBox(width: 6),
              Text(
                _issuesLoading ? 'Syncing live issues…' : 'Live issues from SIH API',
                style: const TextStyle(color: Color(0xFF006B4D), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(tooltip: 'Refresh live issues', onPressed: _issuesLoading ? null : _loadIssues, icon: const Icon(Icons.refresh, size: 18)),
            ],
          ),
          if (_issuesError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Live data unavailable: $_issuesError', style: const TextStyle(color: Colors.red, fontSize: 11)),
            ),
          ..._apiProblems.take(3).map((issue) => Card(
            child: ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Color(0xFF006B4D)),
              title: Text(issue.title),
              subtitle: Text('${issue.category} • ${issue.currentStage}'),
              trailing: Text(issue.priorityLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onTap: () => _navigateTo(AppView.problemDetailView),
            ),
          )),
          // Action Dashboard Cards
          const Text("Action Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.assignment, color: Color(0xFF006B4D)),
              title: const Text("Open drainage near block C"),
              subtitle: const Text("Under Review • Reported Yesterday"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECFDF5)),
                onPressed: () => _navigateTo(AppView.problemDetailView),
                child: const Text("Track",
                    style: TextStyle(color: Color(0xFF006B4D), fontSize: 12)),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.near_me, color: Color(0xFF0284C7)),
              title: const Text("Nearby problem to verify"),
              subtitle: const Text("300m away • Pothole on Sector 18 lane"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7)),
                onPressed: () => _navigateTo(AppView.citizenGeofenceCheck),
                child: const Text("Verify",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF334155),
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _mapPin(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: Colors.white70,
          child: Text(label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 4: CITIZEN REPORT FLOW (5 STEPS)
  // ==========================================
  Widget _buildCitizenReportWizard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("STEP $_reportStep OF 5",
                  style: const TextStyle(
                      color: Color(0xFF006B4D),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              IconButton(
                  onPressed: () => _navigateTo(AppView.citizenHome),
                  icon: const Icon(Icons.close)),
            ],
          ),
          LinearProgressIndicator(
              value: _reportStep / 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF006B4D)),
          const SizedBox(height: 20),

          // STEP 1: ADD EVIDENCE
          if (_reportStep == 1) ...[
            const Text("Step 1: Add Evidence",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1))),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Color(0xFF64748B)),
                  SizedBox(height: 8),
                  Text("Take Photo or Upload from Gallery",
                      style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () => setState(() => _reportStep = 2),
              child: const Text("Continue to Description",
                  style: TextStyle(color: Colors.white)),
            ),
          ],

          // STEP 2: DESCRIBE THE PROBLEM
          if (_reportStep == 2) ...[
            const Text("Step 2: Describe the Problem",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _reportTitleController,
              maxLength: 140,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., Large pothole near the college entrance",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text("Category Selection:",
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              onChanged: (val) =>
                  setState(() => _citizenSelectedCategory = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () => setState(() => _reportStep = 3),
              child: const Text("Confirm Location",
                  style: TextStyle(color: Colors.white)),
            ),
          ],

          // STEP 3: CONFIRM LOCATION
          if (_reportStep == 3) ...[
            const Text("Step 3: Confirm Location",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              height: 150,
              color: const Color(0xFFCBD5E1),
              child: const Center(
                  child: Text(
                      "GPS Detected: 28.5355° N, 77.3910° E\nAdjust Pin on Map")),
            ),
            const SizedBox(height: 12),
            const Text("Address Preview: Sector 18, Gate 2 Metro Exit",
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () => setState(() => _reportStep = 4),
              child: const Text("Run AI Understanding Check",
                  style: TextStyle(color: Colors.white)),
            ),
          ],

          // STEP 4: AI UNDERSTANDING & DEDUPLICATION (From Screenshot 1000100135)
          if (_reportStep == 4) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Text("CIVICAI COPILOT • Reviewable Preview",
                      style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Detected Category: Road damage (94% Confidence)",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                        "Estimated Severity: High (Structural asphalt failure)",
                        style: TextStyle(color: Colors.red)),
                    SizedBox(height: 12),
                    Divider(),
                    Text("SIMILAR NEARBY ISSUE DETECTED",
                        style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    SizedBox(height: 4),
                    Text(
                        "#TR-8812 - Deep pothole outside Metro Pillar 42 (120m away)"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: _submitIssue,
              child: const Text("+ Add Evidence to Existing Problem #TR-8812",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: _submitIssue,
              child: const Text("Continue as New Report"),
            ),
          ],

          // STEP 5: SUBMISSION CONFIRMATION
          if (_reportStep == 5) ...[
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Color(0xFF10B981)),
                  SizedBox(height: 12),
                  Text("Report Submitted Successfully!",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Problem ID: #${_submittedIssueId ?? 'TR-4092'}",
                      style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                  Text("Status: Reported ➔ AI Review Pending"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () => _navigateTo(AppView.problemDetailView),
              child: const Text("View Problem Details",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 5: GEOFENCED VERIFICATION PROMPT (Screenshot 1000100117)
  // ==========================================
  Widget _buildCitizenGeofencePrompt() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        "GEOFENCE TRIGGERED: You are within 60m of a reported civic problem",
                        style: TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Severe Asphalt Pothole near Pillar 42",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("#TR-8812 • Priority Index: High (340 cars/h)",
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          const Text("Can you confirm whether this problem still exists?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Verification recorded! +15 Civic Karma")));
              _navigateTo(AppView.citizenHome);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text("Yes, it still exists",
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () => _navigateTo(AppView.citizenHome),
            icon: const Icon(Icons.close),
            label: const Text("No, it appears resolved"),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _navigateTo(AppView.citizenHome),
            child: const Center(child: Text("Not sure / Can't see clearly")),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
              "ROLE PROTOCOL DISTINCTION:\nCitizens provide community verification evidence. Students submit official engineering completion evidence.",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 6: PROBLEM DETAIL & LIFECYCLE (Screenshot 1000100123)
  // ==========================================
  Widget _buildProblemDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => _navigateTo(AppView.citizenHome),
                  icon: const Icon(Icons.arrow_back)),
              const Text("Docket #TR-8812",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text("UNDER EXECUTION",
                    style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // STRICT SEPARATION OF PRIORITY AND COMPLEXITY CARDS
          const Row(
            children: [
              Expanded(
                child: Card(
                  color: Color(0xFFFEF2F2),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CIVIC IMPACT VECTOR",
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        Text("Priority: High",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red)),
                        SizedBox(height: 4),
                        Text(
                            "• Severity: Critical Tier 1\n• 1,450 Commuters Daily\n• 24 Citizen Reports\n• Recency: 2h ago",
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  color: Color(0xFFF0F9FF),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("EXECUTION LOGISTICS",
                            style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold)),
                        Text("Complexity: Med",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0284C7))),
                        SizedBox(height: 4),
                        Text(
                            "• 3 Days Turnaround\n• Asphalt Compacting\n• Bitumen & Barriers\n• Cost: \$420 USD",
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text("Lifecycle Milestone Audit",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _timelineStep("1. Reported", "Oct 12 via Citizen App", true),
          _timelineStep("2. AI Understood",
              "Vision model identified asphalt fissure", true),
          _timelineStep(
              "3. Community Verified", "Validated by 24 local residents", true),
          _timelineStep(
              "4. Prioritized", "Elevated to High Priority (#4 Ward 14)", true),
          _timelineStep("5. Taken up by Industrialist",
              "Apex Infra Corp (\$420 Capital)", true),
          _timelineStep(
              "6. Students Selected", "Team Apex Civic Lab (4 Students)", true),
          _timelineStep("7. Under Execution",
              "Civil asphalt compaction in progress", true),
          _timelineStep(
              "8. Evidence Submitted", "Pending student EXIF upload", false),
          _timelineStep("9. Outcome Verified",
              "Independent resident sign-off pending", false),
        ],
      ),
    );
  }

  Widget _timelineStep(String title, String subtitle, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? const Color(0xFF006B4D) : const Color(0xFFCBD5E1),
              size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8))),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 7: STUDENT DASHBOARD (Screenshot 1000100153)
  // ==========================================
  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  backgroundColor: Color(0xFF0284C7),
                  child: Text("RV", style: TextStyle(color: Colors.white))),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Rohan Verma ✓",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Civil & Environmental Eng. (3rd Yr)",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12)),
                child: const Text("• Available",
                    style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatBox(value: "12", label: "Recommended"),
              _StatBox(value: "2", label: "Applications"),
              _StatBox(value: "1", label: "Active Project"),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Field Challenges Available",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ..._problems.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.category,
                              style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                          Text(p.priorityLabel,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(p.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Skills Required: ${p.requiredSkills}",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.business,
                                size: 16, color: Color(0xFF0F172A)),
                            const SizedBox(width: 6),
                            Text("Sponsor: ${p.sponsorName}",
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006B4D)),
                          onPressed: () =>
                              _navigateTo(AppView.studentApplication),
                          child: const Text("View Challenge & Submit Proposal",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 8: STUDENT APPLICATION & PROPOSAL (Screenshot 1000100138)
  // ==========================================
  Widget _buildStudentApplicationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                  onPressed: () => _navigateTo(AppView.studentHome),
                  icon: const Icon(Icons.arrow_back)),
              const Text("Submit Engineering Approach",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Damaged Streetlight Cluster",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                      "Sponsor: Apex Energy Labs • Budget: \$350 Parts Allocated"),
                  Divider(height: 24),
                  Text("Proposed Technical Solution",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                        hintText:
                            "Explain bypass, driver tests, grounding checks...",
                        border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12),
                  Text("Estimated Commitment: 8 Hours over weekend",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "Approach Submitted to Mentor! Status: Under Review")));
              _navigateTo(AppView.studentWorkspace);
            },
            child: const Text("Submit Proposal to Mentor",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 9: STUDENT EXECUTION WORKSPACE (Screenshot 1000100129)
  // ==========================================
  Widget _buildStudentWorkspaceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DOCKET #TR-7721",
              style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const Text("Reconstruction of Sector 14 Conduit",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Mentor: Dr. Arvind Swamy (Apex Energy)",
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12)),
            child: const Text(
              "EXPLICIT STATUS: Your team reports that the planned intervention has been carried out.\nNotice: Not yet marked resolved. Requires objective outcome verification.",
              style: TextStyle(color: Color(0xFF1E40AF), fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Field Intervention Checklist (75% Done)",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _checkItem(
              "Isolate circuit junction 4B", true, "Signed off by Vikram P."),
          _checkItem(
              "Rewire burnt copper traces", true, "Thermal bridge replaced"),
          _checkItem(
              "Install IP67 weatherproof seal", true, "Dual gasket seated"),
          _checkItem("Capture geolocated night illuminance photo", false,
              "Required for milestone completion"),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () => _navigateTo(AppView.studentEvidenceSubmit),
            child: const Text("Proceed to Evidence Submission →",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String title, bool done, String detail) {
    return Card(
      child: ListTile(
        leading: Icon(done ? Icons.check_box : Icons.check_box_outline_blank,
            color: done ? const Color(0xFF006B4D) : Colors.grey),
        title: Text(title,
            style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                fontSize: 14)),
        subtitle: Text(detail, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  // ==========================================
  // SCREEN 10: COMPLETION EVIDENCE SUBMISSION (Screenshot 1000100141)
  // ==========================================
  Widget _buildStudentEvidenceSubmissionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Photographic Audit • DUAL-PROOF MATCHED",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  color: const Color(0xFFE2E8F0),
                  child: const Center(
                      child: Text("BEFORE\nOriginal Incident",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 120,
                  color: const Color(0xFFDCFCE7),
                  child: const Center(
                      child: Text("RESOLVED: AFTER\nEXIF Geo-Tagged",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.green))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Work Performed Summary:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
              "• Replaced 150W transformers\n• Re-crimped terminal leads\n• Sealed IP67 enclosure"),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                  value: _confirmCheck,
                  onChanged: (v) => setState(() => _confirmCheck = v!)),
              const Expanded(
                child: Text(
                    "I confirm that this evidence accurately represents work carried out by the team.",
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B4D),
                minimumSize: const Size(double.infinity, 48)),
            onPressed: _confirmCheck
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Submitted! Status: Execution Evidence Submitted — Outcome Verification Pending")));
                    _navigateTo(AppView.industrialistAuditVerdict);
                  }
                : null,
            child: const Text("Submit for Outcome Verification",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 11: INDUSTRIALIST DASHBOARD (Screenshot 1000100150)
  // ==========================================
  Widget _buildIndustrialistDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                  backgroundColor: Color(0xFF0F172A),
                  child: Text("SS", style: TextStyle(color: Colors.white))),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Siddharth Singhania",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("VP, Apex Infra Ventures • Tier Civic Patron",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatBoxSmall(value: "18", label: "Prioritized"),
              _StatBoxSmall(value: "4", label: "Taken Up"),
              _StatBoxSmall(value: "3", label: "Active Teams"),
              _StatBoxSmall(value: "7", label: "Pending Apps"),
              _StatBoxSmall(value: "2", label: "Evidence Review"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Vetted Civic Interventions",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                  onPressed: () =>
                      _navigateTo(AppView.industrialistSquadSelect),
                  child: const Text("Manage Squads")),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ward 14, Sector 18 Junction",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text("Critical crossroad sinkhole & bitumen collapse",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text(
                      "Required Patronage: \$420 Capital + Bitumen Compactor"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006B4D)),
                          onPressed: () =>
                              _navigateTo(AppView.industrialistSquadSelect),
                          child: const Text("Take Up Problem",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () =>
                            _navigateTo(AppView.industrialistLiveFeed),
                        child: const Text("Live Feed"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 12: INDUSTRIALIST SQUAD SELECTION (Screenshot 1000100144)
  // ==========================================
  Widget _buildIndustrialistSquadSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sponsor Grant Commitment",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Sector 18 Road Infrastructure • 4 Candidate Applicants",
              style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          _applicantCard(
              "Aarav Mehta (98% Match)",
              "Civil Engineering • Final Year",
              "Proposed: Cold-pour asphalt emulsion with gravel compaction layer"),
          const SizedBox(height: 8),
          _applicantCard(
              "Priya Das (91% Match)",
              "Urban Infrastructure • 3rd Year",
              "Proposed: Topographical survey & rapid drainage routing"),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SQUAD AUTHORIZATION DOSSIER",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      "Team Finalized! Escrow Smart Contract Activated.")));
              _navigateTo(AppView.industrialistLiveFeed);
            },
            child: const Text("Finalize Team & Authorize Work",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _applicantCard(String name, String dept, String proposal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(dept,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(proposal, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B4D)),
              onPressed: () {},
              child: const Text("Add to Team",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 13: MENTORSHIP WORKSPACE & LIVE FEED (Screenshot 1000100132)
  // ==========================================
  Widget _buildIndustrialistLiveFeedView() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("LIVE WORKSPACE • Sector 18 Asphalt Repair",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Quality Index: 94/100 | Escrow Released: \$1,450 / \$2.2k",
                  style: TextStyle(color: Color(0xFF059669), fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _feedTile(
                  "Aarav Patel (Student Lead)",
                  "14:15 - Sub-base gravel leveled. Compactor machine received from depot.",
                  Icons.engineering),
              _feedTile(
                  "Siddharth Mehta (Mentor)",
                  "14:30 - Looks clean. Ensure ambient surface temperature is above 18°C.",
                  Icons.verified_user),
              _feedTile(
                  "Resource Allocation Bot",
                  "15:02 - Micro-grant draw: \$42.00 dispatched for safety cones.",
                  Icons.attach_money),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                      hintText: "Reply to team / send mentor guidance...",
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send, color: Color(0xFF006B4D))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feedTile(String author, String msg, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF006B4D)),
        title: Text(author,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(msg, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // ==========================================
  // SCREEN 14: AUDIT VERDICT & REWORK DIRECTIVES (Screenshot 1000100120)
  // ==========================================
  Widget _buildIndustrialistAuditVerdictView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Docket #TR-7721 • INDEPENDENT AUDIT",
              style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const Text("Ground Evidence & Verdict Decision",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFFF8FAFC),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Student Report: Apex Civic Lab",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Verified GPS: 28.5356° N, 77.3911° E"),
                  Text("Community Consensus: 93% (14 Citizens Confirmed)"),
                  Text("Current Audit Verdict Status: REWORK REQUIRED",
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Select Audit Verdict:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981)),
                  onPressed: () => setState(() => _auditVerdict = "Resolved"),
                  child: const Text("Resolved",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => setState(() => _auditVerdict = "Rework"),
                  child: const Text("Rework",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => setState(() => _auditVerdict = "Disputed"),
                  child: const Text("Disputed",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
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
                  border: Border.all(color: Colors.orange)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("REWORK DIRECTIVE MANDATE (SLO: 48 Hrs)",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 11)),
                  SizedBox(height: 4),
                  Text(
                      "Required Correction: Inspect grounding wire connection on lower mast; clamp appears loose."),
                  SizedBox(height: 4),
                  Text(
                      "Additional Mandate: High-res macro photo of grounding bolt."),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        "Rework Order Dispatched to Student Team (48h SLO).")));
                _navigateTo(AppView.industrialistHome);
              },
              child: const Text("Dispatch Rework Order (48hr SLO)",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE HELPER STAT WIDGETS
// ==========================================
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006B4D))),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatBoxSmall extends StatelessWidget {
  final String value;
  final String label;
  const _StatBoxSmall({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
