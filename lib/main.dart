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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PhishAwareApp());
}

class PhishAwareApp extends StatelessWidget {
  const PhishAwareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishAware',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      initialRoute: Routes.login,
      routes: {
        Routes.login: (_) => const LoginScreen(),
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
  }
}
