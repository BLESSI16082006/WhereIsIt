import 'package:flutter/material.dart';

import '../../screens/authentication/admin_login_screen.dart';
import '../../screens/authentication/login_screen.dart';
import '../../screens/authentication/register_screen.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/home/search_filter_screen.dart';

import '../../screens/user/my_account_screen.dart';
import '../../screens/user/about_screen.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // ROUTE NAMES
  // ------------------------------------------------------------

  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin-login';

  // ------------------------------------------------------------
  // MODULE 2 - USER ACCESS / HOME
  // ------------------------------------------------------------

  static const String home = '/home';
  static const String account = '/account';
  static const String about = '/about';
  static const String searchFilter = '/search-filter';

  // ------------------------------------------------------------
  // FUTURE MODULES
  // ------------------------------------------------------------

  static const String lostItems = '/lost-items';
  static const String foundItems = '/found-items';
  static const String myItems = '/my-items';
  static const String createPost = '/create-post';

  // ------------------------------------------------------------
  // ROUTE GENERATOR
  // ------------------------------------------------------------

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // ==========================================================
      // AUTHENTICATION
      // ==========================================================

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case adminLogin:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginScreen(),
        );

      // ==========================================================
      // MODULE 2 - USER ACCESS / HOME
      // ==========================================================

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case account:
        return MaterialPageRoute(
          builder: (_) => const MyAccountScreen(),
        );

      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );

      case searchFilter:
        return MaterialPageRoute(
          builder: (_) => const SearchFilterScreen(),
        );

      // ==========================================================
      // FUTURE MODULES
      // ==========================================================

      case lostItems:
      case foundItems:
      case myItems:
      case createPost:
        return _notImplementedRoute(settings.name);

      // ==========================================================
      // UNKNOWN ROUTE
      // ==========================================================

      default:
        return _errorRoute(
          'Route not found: ${settings.name}',
        );
    }
  }

  // ------------------------------------------------------------
  // FUTURE MODULE PLACEHOLDER
  // ------------------------------------------------------------

  static Route<dynamic> _notImplementedRoute(
    String? routeName,
  ) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Coming Soon'),
        ),
        body: Center(
          child: Text(
            'This screen will be implemented later.\n\n'
            'Route: $routeName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UNKNOWN ROUTE SCREEN
  // ------------------------------------------------------------

  static Route<dynamic> _errorRoute(
    String message,
  ) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}