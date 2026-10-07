
import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _navigationTimer;

  // ============================================================
  // WHEREISIT COLORS
  // ============================================================

  static const Color backgroundColor =
      Color(0xFF0B1120);

  static const Color primaryBlue =
      Color(0xFF3B82F6);

  static const Color lightBlue =
      Color(0xFF60A5FA);

  static const Color whiteColor =
      Color(0xFFFFFFFF);

  static const Color secondaryText =
      Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // LOGO ANIMATION
    // ----------------------------------------------------------

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // ----------------------------------------------------------
    // GO TO LOGIN
    // ----------------------------------------------------------

    _navigationTimer = Timer(
      const Duration(
        milliseconds: 2200,
      ),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (
              context,
              child,
            ) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =================================================
                // LOGO
                // =================================================

                Image.asset(
                  'assets/images/whereisit_logo.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 12),

                // =================================================
                // APP NAME
                // =================================================

                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Where',
                        style: TextStyle(
                          color: whiteColor,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'IsIt',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // TAGLINE
                // =================================================

                const Text(
                  'Find it. Match it. Recover it.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 34),

                // =================================================
                // LOADING INDICATOR
                // =================================================

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      lightBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
