
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';

  static const Color primaryColor = Color(0xFF111111);
  static const Color accentColor = Color(0xFF00A6A6);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _getUsers() {
    return _firestore
        .collection('users')
        .orderBy('name')
        .snapshots();
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
  ) {
    if (_searchText.isEmpty) {
      return true;
    }

    final String name =
        data['name']?.toString().toLowerCase() ?? '';

    final String email =
        data['email']?.toString().toLowerCase() ?? '';

    final String phone =
        data['phone']?.toString().toLowerCase() ?? '';

    return name.contains(_searchText) ||
        email.contains(_searchText) ||
        phone.contains(_searchText);
  }

  String _readString(
    Map<String, dynamic> data,
    String field,
  ) {
    final value = data[field];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day =
          date.day.toString().padLeft(2, '0');

      final String month =
          date.month.toString().padLeft(2, '0');

      final String year =
          date.year.toString();

      return '$day/$month/$year';
    }

    if (value is DateTime) {
      final String day =
          value.day.toString().padLeft(2, '0');

      final String month =
          value.month.toString().padLeft(2, '0');

      return '$day/$month/${value.year}';
    }

    return 'Not available';
  }

  Future<void> _showUserDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    final String userId = document.id;

    final String name =
        _readString(data, 'name').isEmpty
            ? 'No name'
            : _readString(data, 'name');

    final String email =
        _readString(data, 'email').isEmpty
            ? 'No email'
            : _readString(data, 'email');

    final String phone =
        _readString(data, 'phone').isEmpty
            ? 'Not provided'
            : _readString(data, 'phone');

    final String role =
        _readString(data, 'role').isEmpty
            ? 'user'
            : _readString(data, 'role');

    final String createdAt =
        _formatDate(data['createdAt']);

    final bool isCurrentAdmin =
        _auth.currentUser?.uid == userId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            10,
          ),
          title: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'User Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  Icons.person_outline,
                  'Name',
                  name,
                ),
                _buildDetailRow(
                  Icons.email_outlined,
                  'Email',
                  email,
                ),
                _buildDetailRow(
                  Icons.phone_outlined,
                  'Phone',
                  phone,
                ),
                _buildDetailRow(
                  Icons.admin_panel_settings_outlined,
                  'Role',
                  role,
                ),
                _buildDetailRow(
                  Icons.calendar_today_outlined,
                  'Created',
                  createdAt,
                ),
                const SizedBox(height: 8),
                Text(
                  'User ID',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  userId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: accentColor,
                ),
              ),
            ),
            if (!isCurrentAdmin)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _confirmDeleteUser(
                    document,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text('Delete User'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUser(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final Map<String, dynamic> data =
        document.data();

    final String userId = document.id;

    if (_auth.currentUser?.uid == userId) {
      _showMessage(
        'You cannot delete the currently logged-in administrator.',
        isError: true,
      );
      return;
    }

    final String name =
        _readString(data, 'name').isEmpty
            ? 'this user'
            : _readString(data, 'name');

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete User?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete the '
            'Firestore account record for "$name"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteUserDocument(
      userId,
    );
  }

  Future<void> _deleteUserDocument(
    String userId,
  ) async {
    try {
      if (_auth.currentUser?.uid == userId) {
        _showMessage(
          'You cannot delete the currently logged-in administrator.',
          isError: true,
        );
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .delete();

      if (!mounted) {
        return;
      }

      _showMessage(
        'User record deleted successfully.',
        isError: false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.message ??
            'Unable to delete the user record.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete the user record.',
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users by name, email or phone',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: accentColor,
          ),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: accentColor,
              width: 2,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String name =
        _readString(data, 'name').isEmpty
            ? 'Unnamed User'
            : _readString(data, 'name');

    final String email =
        _readString(data, 'email').isEmpty
            ? 'No email'
            : _readString(data, 'email');

    final String phone =
        _readString(data, 'phone').isEmpty
            ? 'No phone number'
            : _readString(data, 'phone');

    final String role =
        _readString(data, 'role').isEmpty
            ? 'user'
            : _readString(data, 'role');

    final bool isAdmin =
        role.toLowerCase() == 'admin';

    final bool isCurrentAdmin =
        _auth.currentUser?.uid == document.id;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showUserDetails(document);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isAdmin
                      ? Colors.orange.withOpacity(0.12)
                      : accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAdmin
                      ? Icons.admin_panel_settings_outlined
                      : Icons.person_outline,
                  color: isAdmin
                      ? Colors.orange.shade700
                      : accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                color:
                                    Colors.orange.shade800,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCurrentAdmin
                    ? Icons.verified_user_outlined
                    : Icons.arrow_forward_ios_rounded,
                color: isCurrentAdmin
                    ? accentColor
                    : Colors.grey.shade400,
                size: isCurrentAdmin ? 23 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 70,
          horizontal: 30,
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              22,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Accounts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View registered users and manage their account records.',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildEmptyState(
                    title: 'Unable to load users',
                    message:
                        'There was a problem loading user accounts.',
                    icon: Icons.error_outline,
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                    ),
                  );
                }

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    documents =
                    snapshot.data?.docs ?? [];

                final List<
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>>
                    filteredDocuments =
                    documents.where((document) {
                  return _matchesSearch(
                    document.data(),
                  );
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        18,
                        20,
                        12,
                      ),
                      child: _buildSearchBar(),
                    ),
                    Expanded(
                      child: filteredDocuments.isEmpty
                          ? _buildEmptyState(
                              title: _searchText.isEmpty
                                  ? 'No users found'
                                  : 'No matching users',
                              message: _searchText.isEmpty
                                  ? 'There are no registered user accounts.'
                                  : 'Try a different name, email or phone number.',
                              icon: Icons.people_outline,
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(
                                20,
                                4,
                                20,
                                25,
                              ),
                              itemCount:
                                  filteredDocuments.length,
                              itemBuilder:
                                  (context, index) {
                                return _buildUserCard(
                                  filteredDocuments[index],
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

