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

class AppColors {
  static Color bg = const Color(0xFF0A0E14);
  static Color surface = const Color(0xFF131920);
  static Color surface2 = const Color(0xFF1C2535);
  static Color border = const Color(0xFF1E2A3A);
  static Color text = Colors.white;
  static Color textMuted = const Color(0xFF64748B);
  static Color accent = const Color(0xFF00E5A0);
  static Color blue = const Color(0xFF3B82F6);
  static Color warn = const Color(0xFFFFCC00);
  static Color danger = const Color(0xFFFF4444);

  static void apply(bool isDark) {
    if (isDark) {
      bg = const Color(0xFF0A0E14);
      surface = const Color(0xFF131920);
      surface2 = const Color(0xFF1C2535);
      border = const Color(0xFF1E2A3A);
      text = Colors.white;
      textMuted = const Color(0xFF64748B);
      accent = const Color(0xFF00E5A0);
    } else {
      bg = const Color(0xFFF4F6F8);
      surface = const Color(0xFFFFFFFF);
      surface2 = const Color(0xFFE8EDF2);
      border = const Color(0xFFDDE2E8);
      text = const Color(0xFF111827);
      textMuted = const Color(0xFF6B7280);
      accent = const Color(0xFF009E72);
    }
  }
}

class PhishAwareApp extends StatelessWidget {
  const PhishAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPreferences.themeNotifier,
      builder: (_, isDark, __) {
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
    scaffoldBackgroundColor: const Color(0xFF0A0E14),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00E5A0),
      surface: Color(0xFF131920),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );

  ThemeData _buildLightTheme() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F6F8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF009E72),
      surface: Color(0xFFFFFFFF),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
  );
}
