import 'package:flutter/material.dart';

enum AppTab { dashboard, simulations, tips, ranking, history }

class UserStats {
  final int resilience;
  final int xp;
  final String level;

  const UserStats({
    required this.resilience,
    required this.xp,
    required this.level,
  });
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  const QuizQuestion({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class Simulation {
  final String id;
  final String title;
  final int progress;
  final String status;
  final bool completed;
  final List<QuizQuestion>? questions;

  const Simulation({
    required this.id,
    required this.title,
    required this.progress,
    required this.status,
    this.completed = false,
    this.questions,
  });
}

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF1A1F26);
  static const Color surface = Color(0xFF262D35);
  static const Color surface2 = Color(0xFF334155);
  static const Color border = Color(0x1AFFFFFF);
  static const Color accent = Color(0xFF10B981);
  static const Color accentAlt = Color(0xFF00C87A);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color accent2 = Color(0xFFF57C6B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color text = Color(0xFFE2E8F0);
}

class Routes {
  Routes._();

  static const String login = '/';
  static const String dashboard = '/dashboard';
  static const String quiz = '/quiz';
  static const String result = '/result';
  static const String assistant = '/assistant';
  static const String profile = '/profile';
  static const String ranking = '/ranking';
  static const String tips = '/tips';
  static const String sims = '/simulations';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

enum StepType { email, sms, browser, qr, analysis, decision }

class _SimStep {
  final StepType type;
  final String title;
  final String subtitle;
  final String content;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String audioCorrect;
  final String audioWrong;

  const _SimStep({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.audioCorrect,
    required this.audioWrong,
  });
}
