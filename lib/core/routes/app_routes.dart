import '../../screens/items/create_post_screen.dart';
import '../../screens/items/my_items_screen.dart';
import '../../screens/items/found_items_screen.dart';
import 'package:flutter/material.dart';

import '../../screens/authentication/admin_login_screen.dart';
import '../../screens/authentication/login_screen.dart';
import '../../screens/authentication/register_screen.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/home/search_filter_screen.dart';

import '../../screens/user/my_account_screen.dart';
import '../../screens/user/about_screen.dart';
import '../../screens/user/notifications_screen.dart';

import '../../screens/items/lost_items_screen.dart';

import '../../screens/items/post_details_screen.dart';

class AppRoutes {
  // ------------------------------------------------------------
  // AUTHENTICATION
  // ------------------------------------------------------------

  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin-login';

  // ------------------------------------------------------------
  // MODULE 2 - HOME / USER
  // ------------------------------------------------------------

  static const String home = '/home';
  static const String account = '/account';
  static const String about = '/about';
  static const String notifications = '/notifications';

  // ------------------------------------------------------------
  // MODULE 3 - ITEMS
  // ------------------------------------------------------------

  static const String lostItems = '/lost-items';
  static const String foundItems = '/found-items';
  static const String myItems = '/my-items';
  static const String createPost = '/create-post';
  static const String searchFilter = '/search-filter';
  static const String postDetails = '/post-details';
  // ------------------------------------------------------------
  // ROUTE GENERATOR
  // ------------------------------------------------------------

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // ----------------------------------------------------------
      // AUTHENTICATION
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // HOME
      // ----------------------------------------------------------

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      // ----------------------------------------------------------
      // USER
      // ----------------------------------------------------------

      case account:
        return MaterialPageRoute(
          builder: (_) => const MyAccountScreen(),
        );

      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      // ----------------------------------------------------------
      // LOST ITEMS
      // ----------------------------------------------------------

      case lostItems:
        return MaterialPageRoute(
          builder: (_) => LostItemsScreen(),
        );

      // ----------------------------------------------------------
      // SEARCH FILTER
      // ----------------------------------------------------------

      case searchFilter:
        return MaterialPageRoute(
          builder: (_) => const SearchFilterScreen(),
        );

      // ----------------------------------------------------------
      // FUTURE ROUTES
      // ----------------------------------------------------------

      case foundItems:
        return MaterialPageRoute(
          builder: (_) => FoundItemsScreen(),
        );

      case myItems:
        return MaterialPageRoute(
          builder: (_) => MyItemsScreen(),
        );

      case createPost:
        return MaterialPageRoute(
          builder: (_) => const CreatePostScreen(),
        );

      case postDetails:
        final post = settings.arguments as Map<String, dynamic>;
      
        return MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            post: post,
          ),
        );

      // ----------------------------------------------------------
      // UNKNOWN ROUTE
      // ----------------------------------------------------------

      default:
        return _errorRoute(
          'Route not found: ${settings.name}',
        );
    }
  }

  // ------------------------------------------------------------
  // COMING SOON
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
  // ERROR ROUTE
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