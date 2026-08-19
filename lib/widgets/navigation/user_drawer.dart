import 'package:flutter/material.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({super.key});

  // ------------------------------------------------------------
  // CHOCOLATE BROWN
  // ------------------------------------------------------------

  static const Color _darkChocolate =
      Color(0xFF2B1712);

  // ------------------------------------------------------------
  // NAVIGATE
  // ------------------------------------------------------------

  void _navigate(
    BuildContext context,
    String route,
  ) {
    Navigator.pop(context);

    Navigator.pushNamed(
      context,
      route,
    );
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                color: _darkChocolate,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 38,
                      color: Colors.teal.shade700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'WhereIsIt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Lost & Found Service',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // MENU
            // ----------------------------------------------------

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ),
                children: [
                  // ------------------------------------------------
                  // HOME
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.home_outlined,
                    ),
                    title: const Text('Home'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  // ------------------------------------------------
                  // MY ACCOUNT
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                    ),
                    title: const Text('My Account'),
                    onTap: () {
                      _navigate(
                        context,
                        '/account',
                      );
                    },
                  ),

                  // ------------------------------------------------
                  // LOST ITEMS
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.search_off_outlined,
                    ),
                    title: const Text('Lost Items'),
                    onTap: () {
                      _navigate(
                        context,
                        '/lost-items',
                      );
                    },
                  ),

                  // ------------------------------------------------
                  // FOUND ITEMS
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.search_outlined,
                    ),
                    title: const Text('Found Items'),
                    onTap: () {
                      _navigate(
                        context,
                        '/found-items',
                      );
                    },
                  ),

                  // ------------------------------------------------
                  // MY ITEMS
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    title: const Text('My Items'),
                    onTap: () {
                      _navigate(
                        context,
                        '/my-items',
                      );
                    },
                  ),

                  // ------------------------------------------------
                  // NOTIFICATIONS
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                    ),
                    title: const Text('Notifications'),
                    onTap: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notifications will be available soon.',
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(
                    height: 24,
                  ),

                  // ------------------------------------------------
                  // ABOUT
                  // ------------------------------------------------

                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                    ),
                    title: const Text('About'),
                    onTap: () {
                      _navigate(
                        context,
                        '/about',
                      );
                    },
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // LOGOUT
            // ----------------------------------------------------

            const Divider(height: 1),

            ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red.shade700,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}