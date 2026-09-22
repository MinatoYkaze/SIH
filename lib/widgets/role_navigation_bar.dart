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
    final items = <_RoleNavItem>[
      _RoleNavItem(
        icon: Icons.home_rounded,
        label: 'Home',
        onTap: () {
          if (currentRole == UserRoleNav.citizen) {
            onNavigate(AppView.citizenHome);
          } else if (currentRole == UserRoleNav.student) {
            onNavigate(AppView.studentHome);
          } else if (currentRole == UserRoleNav.industrialist) {
            onNavigate(AppView.industrialistHome);
          }
        },
      ),
      _RoleNavItem(
        icon: Icons.map_outlined,
        label: 'Explore',
        onTap: () => onNavigate(AppView.problemDetailView),
      ),
    ];

    if (currentRole == UserRoleNav.citizen) {
      items.add(
        _RoleNavItem(
          icon: Icons.add_circle_outline_rounded,
          label: 'Report',
          onTap: () => onNavigate(AppView.citizenReportWizard),
        ),
      );
    }

    if (currentRole == UserRoleNav.student) {
      items.add(
        _RoleNavItem(
          icon: Icons.work_outline_rounded,
          label: 'Workspace',
          onTap: () => onNavigate(AppView.studentWorkspace),
        ),
      );
    }

    if (currentRole == UserRoleNav.industrialist) {
      items.add(
        _RoleNavItem(
          icon: Icons.groups_outlined,
          label: 'Squads',
          onTap: () => onNavigate(AppView.industrialistSquadSelect),
        ),
      );
    }

    items.add(
      _RoleNavItem(
        icon: Icons.verified_outlined,
        label: 'Audit',
        onTap: () {
          if (currentRole == UserRoleNav.industrialist) {
            onNavigate(AppView.industrialistAuditVerdict);
          } else if (currentRole == UserRoleNav.citizen) {
            onNavigate(AppView.citizenGeofenceCheck);
          } else if (currentRole == UserRoleNav.student) {
            onNavigate(AppView.studentEvidenceSubmit);
          }
        },
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 12,
              offset: Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return Expanded(
              child: _NavItem(
                icon: item.icon,
                label: item.label,
                onTap: item.onTap,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoleNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF006B4D),
                size: 21,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
