import 'package:flutter/material.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF111111);
  static const Color accentColor = Color(0xFF00A6A6);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color fieldColor = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // ADMIN LOGIN
  // ------------------------------------------------------------

  Future<void> _adminLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase authentication will be connected through
      // AuthProvider and FirebaseAuthService later.

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      _showMessage(
        'Admin login form validated successfully.',
        isError: false,
      );

      // Later:
      // Navigator.pushReplacementNamed(context, '/admin-home');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to sign in as administrator.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

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
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,

          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accentColor,
            ),
          ),

          suffixIcon: suffixIcon,

          labelStyle: TextStyle(
            color: Colors.grey.shade600,
          ),

          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: accentColor,
              width: 2,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --------------------------------------------------
              // HEADER
              // --------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  15,
                  24,
                  35,
                ),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Admin icon
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Admin Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'WhereIsIt Administration',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // FORM
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // EMAIL
                      _buildTextField(
                        controller: _emailController,
                        label: 'Admin Email',
                        hint: 'Enter administrator email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter admin email';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // PASSWORD
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter admin password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }

                          if (value.length < 6) {
                            return 'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // ADMIN SIGN IN BUTTON
                      // ------------------------------------------------

                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _adminLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            disabledBackgroundColor:
                                accentColor.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_outlined,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Admin Sign In',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ------------------------------------------------
                      // SECURITY INFORMATION
                      // ------------------------------------------------

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.security_outlined,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Administrator access is restricted. '
                                'Only authorized administrators can access '
                                'the management panel.',
                                style: TextStyle(
                                  color: Colors.grey.shade800,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ------------------------------------------------
                      // BACK TO USER LOGIN
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Are you a user? ',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'User Login',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}