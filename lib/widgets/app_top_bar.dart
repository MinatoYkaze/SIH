import 'package:flutter/material.dart';
import '../core/services/service_locator.dart';
import '../screens/common/auth_dialog.dart';

enum UserRoleNav { landing, roleSelect, citizen, student, industrialist }

class AppTopBar extends StatelessWidget {
  final UserRoleNav currentRole;
  final ValueChanged<UserRoleNav> onRoleChanged;

  const AppTopBar({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = ServiceLocator.instance.authManager;

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final profile = auth.currentProfile;
        final isAuthenticated = auth.isAuthenticated;

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
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (isAuthenticated && profile != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xFF006B4D),
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.name.split(' ').first,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              DropdownButton<UserRoleNav>(
                dropdownColor: const Color(0xFF1E293B),
                value: currentRole,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: UserRoleNav.landing,
                    child: Text("Welcome Screen", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: UserRoleNav.roleSelect,
                    child: Text("Role Selection", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: UserRoleNav.citizen,
                    child: Text("Citizen Portal", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: UserRoleNav.student,
                    child: Text("Student Portal", style: TextStyle(color: Colors.white)),
                  ),
                  DropdownMenuItem(
                    value: UserRoleNav.industrialist,
                    child: Text("Industrialist Hub", style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (role) {
                  if (role != null) onRoleChanged(role);
                },
              ),
              const SizedBox(width: 4),
              if (!isAuthenticated)
                IconButton(
                  tooltip: 'Sign In / Register',
                  icon: const Icon(Icons.login, color: Color(0xFF10B981), size: 20),
                  onPressed: () => AuthDialog.show(context),
                )
              else
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                  onPressed: () async {
                    await auth.signOut();
                    onRoleChanged(UserRoleNav.landing);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
