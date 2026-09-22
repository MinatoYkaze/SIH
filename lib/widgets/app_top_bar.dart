import 'package:flutter/material.dart';
import '../core/services/service_locator.dart';
import '../screens/common/auth_dialog.dart';

enum UserRoleNav {
  landing,
  roleSelect,
  citizen,
  student,
  industrialist,
}

class AppTopBar extends StatelessWidget {
  final UserRoleNav currentRole;
  final ValueChanged<UserRoleNav> onRoleChanged;

  const AppTopBar({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
  });

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'citizen':
        return 'CITIZEN';
      case 'student':
        return 'STUDENT';
      case 'industrialist':
      case 'industry':
        return 'INDUSTRY';
      default:
        return 'USER';
    }
  }

  String _pageLabel(UserRoleNav role) {
    switch (role) {
      case UserRoleNav.landing:
        return 'Welcome';
      case UserRoleNav.roleSelect:
        return 'Choose Role';
      case UserRoleNav.citizen:
        return 'Citizen';
      case UserRoleNav.student:
        return 'Student';
      case UserRoleNav.industrialist:
        return 'Industry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ServiceLocator.instance.authManager;

    return AnimatedBuilder(
      animation: auth,
      builder: (context, _) {
        final profile = auth.currentProfile;
        final isAuthenticated = auth.isAuthenticated;

        final firstName = profile?.name.trim().isNotEmpty == true
            ? profile!.name.trim().split(' ').first
            : 'User';

        final roleLabel =
            profile == null ? null : _roleLabel(profile.role);

        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF1E293B),
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // MENU / HOME
                if (currentRole != UserRoleNav.landing)
                  IconButton(
                    tooltip: 'Go to home',
                    onPressed: () {
                      onRoleChanged(UserRoleNav.landing);
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white70,
                      size: 21,
                    ),
                  ),

                // TRANSITION BRAND
                InkWell(
                  onTap: () {
                    onRoleChanged(UserRoleNav.landing);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'TRANSITION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // CURRENT PAGE
                if (currentRole != UserRoleNav.landing)
                  Flexible(
                    child: Text(
                      _pageLabel(currentRole),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const Spacer(),

                // SIGNED-IN ROLE
                if (isAuthenticated && profile != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132A25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1F6B56),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          roleLabel ?? 'USER',
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // USER MENU
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    offset: const Offset(0, 48),
                    color: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF334155),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'home') {
                        onRoleChanged(
                          profile.role.toLowerCase() == 'student'
                              ? UserRoleNav.student
                              : profile.role.toLowerCase() ==
                                      'industrialist'
                                  ? UserRoleNav.industrialist
                                  : UserRoleNav.citizen,
                        );
                      }

                      if (value == 'logout') {
                        await auth.signOut();
                        onRoleChanged(UserRoleNav.landing);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        enabled: false,
                        value: 'profile',
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF006B4D),
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    roleLabel ?? 'USER',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'home',
                        child: Row(
                          children: [
                            Icon(
                              Icons.dashboard_outlined,
                              color: Colors.white70,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'My Dashboard',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFFCA5A5),
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Color(0xFFFCA5A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFF006B4D),
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 90,
                            ),
                            child: Text(
                              firstName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white60,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // SIGN IN
                  OutlinedButton.icon(
                    onPressed: () => AuthDialog.show(context),
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 17,
                    ),
                    label: const Text('Sign In'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6EE7B7),
                      side: const BorderSide(
                        color: Color(0xFF256D59),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
