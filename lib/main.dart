import 'package:flutter/material.dart';
import 'core/routing/app_view.dart';
import 'core/services/service_locator.dart';
import 'screens/citizen/citizen_dashboard_screen.dart';
import 'screens/citizen/citizen_geofence_screen.dart';
import 'screens/citizen/citizen_report_wizard_screen.dart';
import 'screens/citizen/problem_detail_screen.dart';
import 'screens/common/landing_screen.dart';
import 'screens/common/role_selection_screen.dart';
import 'screens/industrialist/audit_verdict_screen.dart';
import 'screens/industrialist/industrialist_dashboard_screen.dart';
import 'screens/industrialist/live_feed_screen.dart';
import 'screens/industrialist/squad_selection_screen.dart';
import 'screens/student/student_application_screen.dart';
import 'screens/student/student_dashboard_screen.dart';
import 'screens/student/student_evidence_screen.dart';
import 'screens/student/student_workspace_screen.dart';
import 'widgets/app_top_bar.dart';
import 'widgets/role_navigation_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.instance.authManager.initialize();
  runApp(const TransitionApp());
}

class TransitionApp extends StatefulWidget {
  const TransitionApp({super.key});

  @override
  State<TransitionApp> createState() => _TransitionAppState();
}

class _TransitionAppState extends State<TransitionApp> {
  UserRoleNav _currentRole = UserRoleNav.landing;
  AppView _currentView = AppView.landing;
  String? _selectedIssueId;

  @override
  void initState() {
    super.initState();
    ServiceLocator.instance.authManager.addListener(_onAuthChanged);
    _checkInitialSession();
  }

  @override
  void dispose() {
    ServiceLocator.instance.authManager.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final auth = ServiceLocator.instance.authManager;

    if (auth.isAuthenticated && auth.currentProfile != null) {
      final role = auth.currentProfile!.role.toLowerCase();

      if (role == 'student') {
        if (_currentRole != UserRoleNav.student) {
          _switchRole(UserRoleNav.student);
        }
      } else if (role == 'industrialist' || role == 'industry') {
        if (_currentRole != UserRoleNav.industrialist) {
          _switchRole(UserRoleNav.industrialist);
        }
      } else {
        if (_currentRole != UserRoleNav.citizen) {
          _switchRole(UserRoleNav.citizen);
        }
      }
    } else if (!auth.isAuthenticated) {
      if (_currentRole != UserRoleNav.landing &&
          _currentRole != UserRoleNav.roleSelect) {
        _switchRole(UserRoleNav.landing);
      }
    }
  }

  void _checkInitialSession() {
    final auth = ServiceLocator.instance.authManager;
    if (auth.isAuthenticated && auth.currentProfile != null) {
      final role = auth.currentProfile!.role.toLowerCase();
      if (role == 'student') {
        _switchRole(UserRoleNav.student);
      } else if (role == 'industrialist' || role == 'industry') {
        _switchRole(UserRoleNav.industrialist);
      } else {
        _switchRole(UserRoleNav.citizen);
      }
    }
  }

  void _navigateTo(AppView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _switchRole(UserRoleNav role) {
    final auth = ServiceLocator.instance.authManager;
    final profileRole =
        auth.currentProfile?.role.toLowerCase().trim();

    if (auth.isAuthenticated && profileRole != null) {
      final requestedRole = switch (role) {
        UserRoleNav.citizen => 'citizen',
        UserRoleNav.student => 'student',
        UserRoleNav.industrialist => 'industrialist',
        _ => null,
      };

      if (requestedRole != null &&
          requestedRole != profileRole &&
          !(profileRole == 'industrialist' && requestedRole == 'industrialist')) {
        final displayRole = profileRole == 'industrialist'
            ? 'INDUSTRY'
            : profileRole.toUpperCase();

        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Access Restricted',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              content: Text(
                'You are signed in as $displayRole.\n\n'
                'You cannot access another role while signed in.\n\n'
                'Please log out and sign in again as the required role.',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    setState(() {
      _currentRole = role;
      switch (role) {
        case UserRoleNav.landing:
          _currentView = AppView.landing;
          break;
        case UserRoleNav.roleSelect:
          _currentView = AppView.roleSelect;
          break;
        case UserRoleNav.citizen:
          _currentView = AppView.citizenHome;
          break;
        case UserRoleNav.student:
          _currentView = AppView.studentHome;
          break;
        case UserRoleNav.industrialist:
          _currentView = AppView.industrialistHome;
          break;
      }
    });
  }

  void _setSelectedIssueId(String issueId) {
    setState(() {
      _selectedIssueId = issueId;
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
              AppTopBar(
                currentRole: _currentRole,
                onRoleChanged: _switchRole,
              ),
              Expanded(child: _buildBody()),
              if (_currentRole != UserRoleNav.landing &&
                  _currentRole != UserRoleNav.roleSelect)
                RoleNavigationBar(
                  currentRole: _currentRole,
                  onNavigate: _navigateTo,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentView) {
      case AppView.landing:
        return LandingScreen(onNavigate: _navigateTo);

      case AppView.roleSelect:
        return RoleSelectionScreen(
          currentRole: _currentRole,
          onRoleChanged: _switchRole,
          onNavigate: _navigateTo,
        );

      // Citizen Views
      case AppView.citizenHome:
        return CitizenDashboardScreen(
          onNavigate: _navigateTo,
          onSelectIssue: _setSelectedIssueId,
        );
      case AppView.citizenReportWizard:
        return CitizenReportWizardScreen(
          onNavigate: _navigateTo,
          onIssueCreated: (id) {
            _setSelectedIssueId(id);
          },
        );
      case AppView.citizenGeofenceCheck:
        return CitizenGeofenceScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
      case AppView.problemDetailView:
        return ProblemDetailScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );

      // Student Views
      case AppView.studentHome:
        return StudentDashboardScreen(
          onNavigate: _navigateTo,
          onSelectIssue: _setSelectedIssueId,
        );
      case AppView.studentApplication:
        return StudentApplicationScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
      case AppView.studentWorkspace:
        return StudentWorkspaceScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
      case AppView.studentEvidenceSubmit:
        return StudentEvidenceScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );

      // Industrialist Views
      case AppView.industrialistHome:
        return IndustrialistDashboardScreen(
          onNavigate: _navigateTo,
          onSelectIssue: _setSelectedIssueId,
        );
      case AppView.industrialistSquadSelect:
        return SquadSelectionScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
      case AppView.industrialistLiveFeed:
        return LiveFeedScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
      case AppView.industrialistAuditVerdict:
        return AuditVerdictScreen(
          onNavigate: _navigateTo,
          issueId: _selectedIssueId,
        );
    }
  }
}
