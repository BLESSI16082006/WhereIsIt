import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WhereIsItApp());
}

class WhereIsItApp extends StatelessWidget {
  const WhereIsItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhereIsIt',

      debugShowCheckedModeBanner: false,

      // --------------------------------------------------------
      // THEME
      // --------------------------------------------------------

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008C95),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF7F8FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF008C95),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFFE0E0E0),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(14),
            ),
            borderSide: BorderSide(
              color: Color(0xFF008C95),
              width: 2,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF008C95),
            foregroundColor: Colors.white,
            minimumSize: const Size(
              double.infinity,
              52,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      // --------------------------------------------------------
      // INITIAL SCREEN
      // --------------------------------------------------------

      initialRoute: AppRoutes.login,

      // --------------------------------------------------------
      // ROUTES
      // --------------------------------------------------------

      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}