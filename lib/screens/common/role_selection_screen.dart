import 'package:flutter/material.dart';
import '../../core/routing/app_view.dart';
import '../../core/services/service_locator.dart';
import '../../models/profile.dart';
import '../../widgets/app_top_bar.dart';
import 'auth_dialog.dart';

class RoleSelectionScreen extends StatelessWidget {
  final UserRoleNav currentRole;
  final ValueChanged<UserRoleNav> onRoleChanged;
  final ValueChanged<AppView> onNavigate;

  const RoleSelectionScreen({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
    required this.onNavigate,
  });

  Future<void> _handleRoleSelect(BuildContext context, UserRoleNav role, String roleName) async {
    final auth = ServiceLocator.instance.authManager;

    if (!auth.isAuthenticated) {
      AuthDialog.show(
        context,
        initialRole: roleName,
        onAuthenticated: () {
          onRoleChanged(role);
          _navigateToRole(role);
        },
      );
      return;
    }

    // Authenticated user selecting role: update backend profile
    try {
      final profileService = ServiceLocator.instance.profileService;
      final updated = await profileService.updateProfile({'role': roleName});
      auth.setProfile(updated);
    } catch (_) {
      final current = auth.currentProfile;
      if (current != null) {
        auth.setProfile(current.copyWith(role: roleName));
      } else {
        auth.setProfile(ProfileModel(
          id: auth.currentUserId ?? '00000000-0000-0000-0000-000000000001',
          name: auth.currentUserEmail?.split('@').first ?? 'User',
          role: roleName,
        ));
      }
    }

    onRoleChanged(role);
    _navigateToRole(role);
  }

  void _navigateToRole(UserRoleNav role) {
    switch (role) {
      case UserRoleNav.citizen:
        onNavigate(AppView.citizenHome);
        break;
      case UserRoleNav.student:
        onNavigate(AppView.studentHome);
        break;
      case UserRoleNav.industrialist:
        onNavigate(AppView.industrialistHome);
        break;
      default:
        onNavigate(AppView.citizenHome);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "02 STEP 2 OF 3",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Choose Your Role",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            "The role selection customizes your civic dashboard and active toolsets.",
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _roleCard(
            context: context,
            role: UserRoleNav.citizen,
            roleKey: "citizen",
            title: "Citizen",
            badge: "Ground Team",
            description: "Community Watch & Local Verification",
            bullets: [
              "Report civic problems",
              "Verify nearby issues",
              "Track outcomes",
            ],
            buttonLabel: "Select Citizen",
          ),
          const SizedBox(height: 16),
          _roleCard(
            context: context,
            role: UserRoleNav.student,
            roleKey: "student",
            title: "Student",
            badge: "Field Unit",
            description: "Hands-on Engineering & Civic Execution",
            bullets: [
              "Discover problems",
              "Join intervention teams",
              "Submit execution evidence",
            ],
            buttonLabel: "Select Student",
          ),
          const SizedBox(height: 16),
          _roleCard(
            context: context,
            role: UserRoleNav.industrialist,
            roleKey: "industrialist",
            title: "Industrialist",
            badge: "Sponsor & Mentor",
            description: "Mentorship, Capital & Resources",
            bullets: [
              "Take up prioritized problems",
              "Select and mentor students",
              "Support practical solutions",
            ],
            buttonLabel: "Select Industrialist",
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required BuildContext context,
    required UserRoleNav role,
    required String roleKey,
    required String title,
    required String badge,
    required String description,
    required List<String> bullets,
    required String buttonLabel,
  }) {
    final bool isSelected = currentRole == role;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF006B4D) : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(b, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF006B4D)
                      : const Color(0xFFCBD5E1),
                ),
                backgroundColor:
                    isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
              ),
              onPressed: () => _handleRoleSelect(context, role, roleKey),
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF006B4D)
                      : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
