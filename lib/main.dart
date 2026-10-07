import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_colors.dart';

import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const WhereIsItApp());
}

class WhereIsItApp extends StatelessWidget {
  const WhereIsItApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: AppColors.primaryBlue,
      secondary: AppColors.lightBlue,
      surface: AppColors.card,
      error: AppColors.error,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'WhereIsIt',

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,
        cardColor: AppColors.card,
        dividerColor: AppColors.border,

        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryText,
          surfaceTintColor: AppColors.background,
        ),

        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: AppColors.card,
        ),

        cardTheme: const CardThemeData(
          color: AppColors.card,
          surfaceTintColor: AppColors.card,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),

        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: AppColors.card,
          titleTextStyle: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          contentTextStyle: TextStyle(
            color: AppColors.secondaryText,
            fontSize: 14,
          ),
        ),

        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: AppColors.card,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card,
          hintStyle: const TextStyle(
            color: AppColors.secondaryText,
          ),
          labelStyle: const TextStyle(
            color: AppColors.secondaryText,
          ),
          prefixIconColor: AppColors.secondaryText,
          suffixIconColor: AppColors.secondaryText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(
              double.infinity,
              50,
            ),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.primaryText,
            disabledBackgroundColor: AppColors.primaryBlue.withValues(
              alpha: 0.45,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: const BorderSide(
              color: AppColors.primaryBlue,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.lightBlue,
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primaryBlue,
        ),

        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.cardElevated,
          contentTextStyle: TextStyle(
            color: AppColors.primaryText,
          ),
        ),
      ),

      // ----------------------------------------------------------
      // ROUTING
      // ----------------------------------------------------------

      onGenerateRoute: AppRoutes.generateRoute,

      // ----------------------------------------------------------
      // FIRST SCREEN
      // ----------------------------------------------------------

      home: const SplashScreen(),
    );
  }
}
