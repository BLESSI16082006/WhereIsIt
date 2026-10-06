import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const Color primaryColor = Color(0xFF111111);
  static const Color accentColor = Color(0xFF00A6A6);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  Stream<int> _getUserCount() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getLostPostCount() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('postType', isEqualTo: 'Lost')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getFoundPostCount() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('postType', isEqualTo: 'Found')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getCompletedPostCount() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Admin Logout'),
          content: const Text(
            'Are you sure you want to logout from the admin panel?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _openUsers(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.adminUsers,
    );
  }

  void _openLostPosts(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.adminLostPosts,
    );
  }

  void _openFoundPosts(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.adminFoundPosts,
    );
  }

  void _openCompletedPosts(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.adminCompletedPosts,
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Stream<int> countStream,
    required VoidCallback onTap,
  }) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final int count = snapshot.data ?? 0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 28,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 17,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      count.toString(),
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        18,
        22,
        28,
      ),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor,
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'WhereIsIt Administration',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _logout(context),
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select a dashboard card to manage users '
              'or posts. Administrator access is restricted '
              'to authorized accounts.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overview',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor your WhereIsIt application.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool wideScreen =
                            constraints.maxWidth >= 700;

                        if (wideScreen) {
                          return GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.7,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStatCard(
                                title: 'Users',
                                subtitle:
                                    'Registered application users',
                                icon:
                                    Icons.people_alt_outlined,
                                iconColor: Colors.blue,
                                countStream:
                                    _getUserCount(),
                                onTap: () =>
                                    _openUsers(context),
                              ),

                              _buildStatCard(
                                title: 'Lost Posts',
                                subtitle:
                                    'Reported lost items',
                                icon: Icons.search_outlined,
                                iconColor: Colors.orange,
                                countStream:
                                    _getLostPostCount(),
                                onTap: () =>
                                    _openLostPosts(context),
                              ),

                              _buildStatCard(
                                title: 'Found Posts',
                                subtitle:
                                    'Reported found items',
                                icon: Icons.inventory_2_outlined,
                                iconColor: Colors.purple,
                                countStream:
                                    _getFoundPostCount(),
                                onTap: () =>
                                    _openFoundPosts(context),
                              ),

                              _buildStatCard(
                                title: 'Completed Posts',
                                subtitle:
                                    'Successfully recovered items',
                                icon:
                                    Icons.check_circle_outline,
                                iconColor: Colors.green,
                                countStream:
                                    _getCompletedPostCount(),
                                onTap: () =>
                                    _openCompletedPosts(context),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildStatCard(
                              title: 'Users',
                              subtitle:
                                  'Registered application users',
                              icon:
                                  Icons.people_alt_outlined,
                              iconColor: Colors.blue,
                              countStream:
                                  _getUserCount(),
                              onTap: () =>
                                  _openUsers(context),
                            ),
                            const SizedBox(height: 16),

                            _buildStatCard(
                              title: 'Lost Posts',
                              subtitle:
                                  'Reported lost items',
                              icon: Icons.search_outlined,
                              iconColor: Colors.orange,
                              countStream:
                                  _getLostPostCount(),
                              onTap: () =>
                                  _openLostPosts(context),
                            ),
                            const SizedBox(height: 16),

                            _buildStatCard(
                              title: 'Found Posts',
                              subtitle:
                                  'Reported found items',
                              icon:
                                  Icons.inventory_2_outlined,
                              iconColor: Colors.purple,
                              countStream:
                                  _getFoundPostCount(),
                              onTap: () =>
                                  _openFoundPosts(context),
                            ),
                            const SizedBox(height: 16),

                            _buildStatCard(
                              title: 'Completed Posts',
                              subtitle:
                                  'Successfully recovered items',
                              icon:
                                  Icons.check_circle_outline,
                              iconColor: Colors.green,
                              countStream:
                                  _getCompletedPostCount(),
                              onTap: () =>
                                  _openCompletedPosts(context),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}