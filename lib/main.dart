import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phishing/screen/notification_screen.dart';
import 'package:phishing/screen/settings_screen.dart';
import 'models/app_models.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/forgot_password_screen.dart';
import 'screen/main_shell.dart';
import 'screen/quiz_screen.dart';
import 'screen/result_screen.dart';
import 'screen/history_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/assistent_screen.dart';
import 'screen/splaceScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.load();
  runApp(const PhishAwareApp());
}

class PhishAwareApp extends StatelessWidget {
  const PhishAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPreferences.themeNotifier,
      builder: (_, isDark, __) {
        // Atualiza as cores do AppColors (definido em app_models.dart)
        AppColors.apply(isDark);

        return MaterialApp(
          title: 'PhishAware',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          initialRoute: Routes.splash,
          routes: {
            Routes.login: (_) => const LoginScreen(),
            Routes.splash: (_) => const SplashScreen(),
            Routes.register: (_) => const RegisterScreen(),
            Routes.forgotPassword: (_) => const ForgotPasswordScreen(),
            Routes.dashboard: (_) => const MainShell(),
            Routes.quiz: (_) => const QuizScreen(),
            Routes.result: (_) => const ResultScreen(),
            Routes.history: (_) => const HistoryScreen(),
            Routes.profile: (_) => const ProfileScreen(),
            Routes.assistant: (_) => const AssistantScreen(),
            Routes.notifications: (_) => const NotificationsScreen(),
            Routes.settings: (_) => const SettingsScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildDarkTheme() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F1318),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5A0),
      secondary: Color(0xFF00C87A),
      surface: Color(0xFF1A2030),
      error: Color(0xFFEF4444),
    ),
    cardColor: const Color(0xFF1A2030),
    dividerColor: const Color(0x1AFFFFFF),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F1318),
      foregroundColor: Color(0xFFE2E8F0),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF242D3E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00E5A0), width: 1.5),
      ),
    ),
  );

  ThemeData _buildLightTheme() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F7F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00A374),
      secondary: Color(0xFF008A62),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
    ),
    cardColor: const Color(0xFFFFFFFF),
    dividerColor: const Color(0xFFCDD9D4),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F7F5),
      foregroundColor: Color(0xFF0D1F1A),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF0D1F1A)),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF0D1F1A)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEAF2EE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCDD9D4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCDD9D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00A374), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF4B6858)),
      hintStyle: const TextStyle(color: Color(0xFF4B6858)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00A374),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00A374)),
    ),
  );
}
