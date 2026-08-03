import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_user_service.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final FirestoreUserService _userService = FirestoreUserService();

  String _name = '';
  String _email = '';
  String _phone = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD USER PROFILE
  // ============================================================

  Future<void> _loadUserProfile() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final profile = await _userService.getUserProfile(
        firebaseUser.uid,
      );

      if (!mounted) return;

      setState(() {
        _name =
            profile?['name']?.toString() ??
            firebaseUser.displayName ??
            '';

        _email =
            profile?['email']?.toString() ??
            firebaseUser.email ??
            '';

        _phone =
            profile?['phone']?.toString() ??
            '';

        _nameController.text = _name;
        _emailController.text = _email;
        _phoneController.text = _phone;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load profile: $e',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ============================================================
  // START EDITING
  // ============================================================

  void _startEditing() {
    _nameController.text = _name;
    _emailController.text = _email;
    _phoneController.text = _phone;

    setState(() {
      _isEditing = true;
    });
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();

    // ----------------------------------------------------------
    // VALIDATE FIELDS
    // ----------------------------------------------------------

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // GET CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final User? firebaseUser =
        FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No logged-in user found.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // UPDATE FIRESTORE PROFILE
      // --------------------------------------------------------

      await _userService.updateUserProfile(
        userId: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
      );

      // --------------------------------------------------------
      // UPDATE FIREBASE AUTH DISPLAY NAME
      // --------------------------------------------------------

      await firebaseUser.updateDisplayName(name);

      await firebaseUser.reload();

      if (!mounted) return;

      // --------------------------------------------------------
      // UPDATE LOCAL SCREEN DATA
      // --------------------------------------------------------

      setState(() {
        _name = name;
        _email = email;
        _phone = phone;

        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );
    } catch (e) {
      // --------------------------------------------------------
      // SHOW ACTUAL FIREBASE ERROR
      // --------------------------------------------------------

      debugPrint('PROFILE UPDATE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile update failed: $e',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // ============================================================
  // CANCEL EDITING
  // ============================================================

  void _cancelEditing() {
    _nameController.text = _name;
    _emailController.text = _email;
    _phoneController.text = _phone;

    setState(() {
      _isEditing = false;
    });
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // PROFILE HEADER
                  // ==================================================

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.teal.shade50,
                          ),

                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.teal.shade700,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _name.isEmpty
                              ? 'User'
                              : _name,

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // PROFILE INFORMATION TITLE
                  // ==================================================

                  const Text(
                    'Profile Information',

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // NAME
                  // ==================================================

                  _buildTextField(
                    label: 'Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    enabled: _isEditing,
                    keyboardType:
                        TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // PHONE
                  // ==================================================

                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    keyboardType:
                        TextInputType.phone,
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BUTTONS
                  // ==================================================

                  if (!_isEditing)

                    // ------------------------------------------------
                    // EDIT PROFILE BUTTON
                    // ------------------------------------------------

                    SizedBox(
                      width: double.infinity,
                      height: 52,

                      child: ElevatedButton.icon(
                        onPressed: _startEditing,

                        icon: const Icon(
                          Icons.edit_outlined,
                        ),

                        label: const Text(
                          'Edit Profile',

                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )

                  else

                    // ------------------------------------------------
                    // CANCEL + SAVE BUTTONS
                    // ------------------------------------------------

                    Row(
                      children: [
                        // --------------------------------------------
                        // CANCEL
                        // --------------------------------------------

                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : _cancelEditing,

                            style:
                                OutlinedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                double.infinity,
                                52,
                              ),
                            ),

                            child: const Text(
                              'Cancel',
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // --------------------------------------------
                        // SAVE
                        // --------------------------------------------

                        Expanded(
                          child:
                              ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _saveProfile,

                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,

                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.check,
                                  ),

                            label: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : 'Save',
                            ),

                            style:
                                ElevatedButton.styleFrom(
                              minimumSize:
                                  const Size(
                                double.infinity,
                                52,
                              ),

                              backgroundColor:
                                  Colors.green,

                              foregroundColor:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // TEXT FIELD WIDGET
  // ============================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),

        border: const OutlineInputBorder(),

        enabledBorder:
            const OutlineInputBorder(),

        focusedBorder:
            const OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
          ),
        ),
      ),
    );
  }
}