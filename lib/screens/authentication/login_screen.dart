
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================================================
  // WHEREISIT DARK BLUE THEME
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF0B1120);

  static const Color cardColor =
      Color(0xFF172033);

  static const Color primaryBlue =
      Color(0xFF3B82F6);

  static const Color ctaBlue =
      Color(0xFF2563EB);

  static const Color lightBlue =
      Color(0xFF60A5FA);

  static const Color whiteColor =
      Color(0xFFFFFFFF);

  static const Color secondaryText =
      Color(0xFF94A3B8);

  static const Color borderColor =
      Color(0xFF26354D);

  static const Color successColor =
      Color(0xFF22C55E);

  static const Color errorColor =
      Color(0xFFEF4444);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/home',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message =
              'This account has been disabled by the administrator.';
          break;

        case 'too-many-requests':
          message =
              'Too many login attempts. Please try again later.';
          break;

        default:
          message =
              'Unable to sign in. Please try again.';
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
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

  // ============================================================
  // MESSAGE
  // ============================================================

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
              color: whiteColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor:
            isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // WHEREISIT BRANDING
  //
  // The logo is now loaded from:
  //
  // assets/images/whereisit_logo.png
  //
  // The app name is kept as Flutter text so that:
  //
  // "Where" -> White
  // "IsIt"  -> Blue
  //
  // This keeps the PNG reusable as the application icon.
  // ============================================================

  Widget _buildWhereIsItBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --------------------------------------------------------
        // LOGO PNG
        // --------------------------------------------------------

        Image.asset(
          'assets/images/whereisit_logo.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 2),

        // --------------------------------------------------------
        // APP NAME
        // --------------------------------------------------------

        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Where',
                style: TextStyle(
                  color: whiteColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              TextSpan(
                text: 'IsIt',
                style: TextStyle(
                  color: primaryBlue,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Sign in to continue',
          style: TextStyle(
            color: secondaryText,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

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
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        cursorColor: primaryBlue,
        style: const TextStyle(
          color: whiteColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,

          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: lightBlue,
            ),
          ),

          suffixIcon: suffixIcon,

          labelStyle: const TextStyle(
            color: secondaryText,
          ),

          floatingLabelStyle: const TextStyle(
            color: lightBlue,
          ),

          hintStyle: const TextStyle(
            color: secondaryText,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: primaryBlue,
              width: 1.5,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: errorColor,
              width: 1,
            ),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: errorColor,
              width: 1.5,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  34,
                ),
                decoration: const BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: whiteColor,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    // =================================================
                    // PNG LOGO + APP NAME
                    // =================================================

                    _buildWhereIsItBranding(),
                  ],
                ),
              ),

              // ==================================================
              // FORM
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 5),

                      // =================================================
                      // EMAIL
                      // =================================================

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType:
                            TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter your email';
                          }

                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );

                          if (!emailRegex.hasMatch(
                            value.trim(),
                          )) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // PASSWORD
                      // =================================================

                      _buildTextField(
                        controller:
                            _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        obscureText:
                            _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                            color: secondaryText,
                          ),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please enter your password';
                          }

                          if (value.length < 6) {
                            return
                                'Password must contain at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // =================================================
                      // SIGN IN
                      // =================================================

                      SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : _login,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                ctaBlue,
                            disabledBackgroundColor:
                                ctaBlue.withValues(
                              alpha: 0.45,
                            ),
                            foregroundColor:
                                whiteColor,
                            elevation: 5,
                            shadowColor:
                                primaryBlue.withValues(
                              alpha: 0.30,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                18,
                              ),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(
                                      whiteColor,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  children: [
                                    Icon(Icons.login),
                                    SizedBox(width: 10),
                                    Text(
                                      'Sign In',
                                      style:
                                          TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // ADMIN LOGIN
                      // =================================================

                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/admin-login',
                          );
                        },
                        icon: const Icon(
                          Icons
                              .admin_panel_settings_outlined,
                          color: lightBlue,
                        ),
                        label: const Text(
                          'Admin Login',
                          style: TextStyle(
                            color: whiteColor,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          minimumSize:
                              const Size(
                            double.infinity,
                            55,
                          ),
                          backgroundColor:
                              cardColor,
                          side:
                              const BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // =================================================
                      // REGISTER
                      // =================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 15,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/register',
                              );
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: lightBlue,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // =================================================
                      // SECURITY MESSAGE
                      // =================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 17,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Your account information is protected',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

