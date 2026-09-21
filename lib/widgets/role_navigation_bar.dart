import 'package:flutter/material.dart';
import '../core/routing/app_view.dart';
import 'app_top_bar.dart';

class RoleNavigationBar extends StatelessWidget {
  final UserRoleNav currentRole;
  final ValueChanged<AppView> onNavigate;

  const RoleNavigationBar({
    super.key,
    required this.currentRole,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
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
            if (currentRole == UserRoleNav.citizen) {
              onNavigate(AppView.citizenHome);
            } else if (currentRole == UserRoleNav.student) {
              onNavigate(AppView.studentHome);
            } else if (currentRole == UserRoleNav.industrialist) {
              onNavigate(AppView.industrialistHome);
            }
          }),
          _navItem(
            Icons.map,
            "Map/Ops",
            () => onNavigate(AppView.problemDetailView),
          ),
          if (currentRole == UserRoleNav.citizen)
            _navItem(
              Icons.add_circle,
              "Report",
              () => onNavigate(AppView.citizenReportWizard),
            ),
          if (currentRole == UserRoleNav.student)
            _navItem(
              Icons.build,
              "Workspace",
              () => onNavigate(AppView.studentWorkspace),
            ),
          if (currentRole == UserRoleNav.industrialist)
            _navItem(
              Icons.groups,
              "Squads",
              () => onNavigate(AppView.industrialistSquadSelect),
            ),
          _navItem(Icons.verified, "Audit", () {
            if (currentRole == UserRoleNav.industrialist) {
              onNavigate(AppView.industrialistAuditVerdict);
            } else if (currentRole == UserRoleNav.citizen) {
              onNavigate(AppView.citizenGeofenceCheck);
            } else if (currentRole == UserRoleNav.student) {
              onNavigate(AppView.studentEvidenceSubmit);
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
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}
