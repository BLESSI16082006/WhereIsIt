import 'package:flutter/material.dart';

import '../../screens/authentication/admin_login_screen.dart';
import '../../screens/authentication/login_screen.dart';
import '../../screens/authentication/register_screen.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/home/search_filter_screen.dart';

import '../../screens/user/my_account_screen.dart';
import '../../screens/user/about_screen.dart';

import '../../screens/notifications/notifications_screen.dart';

import '../../screens/items/lost_items_screen.dart';
import '../../screens/items/found_items_screen.dart';
import '../../screens/items/my_items_screen.dart';
import '../../screens/items/create_post_screen.dart';
import '../../screens/items/post_details_screen.dart';

import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_users_screen.dart';
import '../../screens/admin/admin_lost_posts_screen.dart';
import '../../screens/admin/admin_found_posts_screen.dart';
import '../../screens/admin/admin_completed_posts_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String adminLogin = '/admin-login';

  // Admin routes
  static const String adminHome = '/admin-home';
  static const String adminUsers = '/admin-users';
  static const String adminLostPosts = '/admin-lost-posts';
  static const String adminFoundPosts = '/admin-found-posts';
  static const String adminCompletedPosts =
      '/admin-completed-posts';

  // User routes
  static const String home = '/home';
  static const String account = '/account';
  static const String about = '/about';
  static const String notifications = '/notifications';

  static const String lostItems = '/lost-items';
  static const String foundItems = '/found-items';
  static const String myItems = '/my-items';
  static const String createPost = '/create-post';
  static const String searchFilter = '/search-filter';
  static const String postDetails = '/post-details';

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // -------------------------
      // Authentication
      // -------------------------

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

      // -------------------------
      // Admin
      // -------------------------

      case adminHome:
        return MaterialPageRoute(
          builder: (_) => const AdminHomeScreen(),
        );

      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminUsersScreen(),
        );

      case adminLostPosts:
        return MaterialPageRoute(
          builder: (_) => const AdminLostPostsScreen(),
        );

      case adminFoundPosts:
        return MaterialPageRoute(
          builder: (_) => const AdminFoundPostsScreen(),
        );

      case adminCompletedPosts:
        return MaterialPageRoute(
          builder: (_) =>
              const AdminCompletedPostsScreen(),
        );

      // -------------------------
      // User
      // -------------------------

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

      case notifications:
        return MaterialPageRoute(
          builder: (_) => NotificationsScreen(),
        );

      case lostItems:
        return MaterialPageRoute(
          builder: (_) => LostItemsScreen(),
        );

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
          builder: (_) => CreatePostScreen(),
        );

      case searchFilter:
        return MaterialPageRoute(
          builder: (_) => const SearchFilterScreen(),
        );

      case postDetails:
        final post =
            settings.arguments as Map<String, dynamic>;

        return MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            post: post,
          ),
        );

      // -------------------------
      // Unknown route
      // -------------------------

      default:
        return _errorRoute(
          'Route not found: ${settings.name}',
        );
    }
  }

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