import 'package:flutter/material.dart';

import '../../screens/authentication/login_screen.dart';
import '../../screens/authentication/register_screen.dart';
import '../../screens/authentication/admin_login_screen.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // ROUTE NAMES
  // ------------------------------------------------------------

  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin-login';

  // These routes will be implemented in later modules.
  static const String home = '/home';
  static const String adminHome = '/admin-home';

  // ------------------------------------------------------------
  // ROUTE GENERATOR
  // ------------------------------------------------------------

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
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

      // --------------------------------------------------------
      // FUTURE ROUTES
      // --------------------------------------------------------
      //
      // We will add these when their modules are implemented:
      //
      // case home:
      //   return MaterialPageRoute(
      //     builder: (_) => const HomeScreen(),
      //   );
      //
      // case adminHome:
      //   return MaterialPageRoute(
      //     builder: (_) => const AdminHomeScreen(),
      //   );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
    }
  }
}