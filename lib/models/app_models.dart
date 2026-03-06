import 'package:flutter/material.dart';

enum AppTab { dashboard, simulations, tips, ranking }

class AppColors {
  AppColors._();
  static const Color bg = Color(0xFF0F1318);
  static const Color surface = Color(0xFF1A2030);
  static const Color surface2 = Color(0xFF242D3E);
  static const Color border = Color(0x1AFFFFFF);
  static const Color accent = Color(0xFF00E5A0);
  static const Color accentAlt = Color(0xFF00C87A);
  static const Color blue = Color(0xFF3B82F6);
  static const Color warn = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color accent2 = Color(0xFFF57C6B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color text = Color(0xFFE2E8F0);
}

class Routes {
  Routes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String quiz = '/quiz';
  static const String result = '/result';
  static const String assistant = '/assistant';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

class UserSession {
  static int userId = 1;
  static String userName = 'Utilizador';
  static String userEmail = '';
  static String avatarLetter = 'U';

  static void setFromLogin(Map<String, dynamic> data) {
    userId = data['id'] ?? 1;
    userName = data['name'] ?? 'Utilizador';
    userEmail = data['email'] ?? '';
    avatarLetter = data['avatar_letter'] ?? userName[0].toUpperCase();
  }
}

class UserStats {
  final int resilience;
  final int xp;
  final String level;
  final int correctTotal;
  final int answeredTotal;
  final Map<String, int> byCategory;

  const UserStats({
    this.resilience = 0,
    this.xp = 0,
    this.level = 'Iniciante',
    this.correctTotal = 0,
    this.answeredTotal = 0,
    this.byCategory = const {"email": 0, "sms": 0, "url": 0, "app": 0},
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
    resilience: (j['resilience'] as num?)?.toInt() ?? 0,
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    level: j['level'] ?? 'Iniciante',
    correctTotal: (j['correct_total'] as num?)?.toInt() ?? 0,
    answeredTotal: (j['answered_total'] as num?)?.toInt() ?? 0,
    byCategory: Map<String, int>.from(
      (j['by_category'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    ),
  );
}

class HistoryEntry {
  final int id;
  final String questionId;
  final String category;
  final bool isCorrect;
  final int points;
  final String scenario;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.questionId,
    required this.category,
    required this.isCorrect,
    required this.points,
    required this.scenario,
    required this.timestamp,
  });

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static bool _parseBool(dynamic raw) {
    if (raw == null) return false;
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';
    return false;
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> j) {
    debugPrint('[HistoryEntry.fromJson] raw=$j');

    return HistoryEntry(
      id: (j['id'] as num?)?.toInt() ?? 0,
      questionId:
          (j['question_id'] ??
                  j['sim_id'] ??
                  j['simulation_id'] ??
                  j['quiz_id'] ??
                  '')
              .toString(),
      category: (j['category'] ?? 'email').toString(),
      isCorrect: _parseBool(j['is_correct']),
      points: (j['points'] as num?)?.toInt() ?? 0,
      scenario:
          (j['scenario'] ??
                  j['title'] ??
                  j['question'] ??
                  j['description'] ??
                  'Simulação sem título')
              .toString(),
      timestamp: _parseDate(
        j['timestamp'] ?? j['created_at'] ?? j['date'] ?? j['answered_at'],
      ),
    );
  }

  String get categoryIcon {
    switch (category) {
      case 'sms':
        return '💬';
      case 'url':
        return '🔗';
      case 'app':
        return '📱';
      default:
        return '📧';
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'sms':
        return AppColors.warn;
      case 'url':
        return AppColors.blue;
      case 'app':
        return AppColors.accent2;
      default:
        return AppColors.accent;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

class RankingUser {
  final int userId;
  final String name;
  final String avatarLetter;
  final int xp;
  final String level;
  final int correctTotal;
  final bool isCurrentUser;

  const RankingUser({
    required this.userId,
    required this.name,
    required this.avatarLetter,
    required this.xp,
    required this.level,
    required this.correctTotal,
    this.isCurrentUser = false,
  });

  factory RankingUser.fromJson(Map<String, dynamic> j, int currentUserId) =>
      RankingUser(
        userId: j['user_id'] ?? 0,
        name: j['name'] ?? 'Utilizador',
        avatarLetter: j['avatar_letter'] ?? 'U',
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        level: j['level'] ?? 'Iniciante',
        correctTotal: (j['correct_total'] as num?)?.toInt() ?? 0,
        isCurrentUser: (j['user_id'] ?? 0) == currentUserId,
      );
}

class PhishSimulation {
  final String id;
  final String title;
  final String description;
  final String threatType;
  final String realImpact;
  final String category;
  final String difficulty;
  final int xp;
  final int progress;
  final bool completed;
  final List<String> questionIds;
  final List<String> tips;

  const PhishSimulation({
    required this.id,
    required this.title,
    required this.description,
    required this.threatType,
    required this.realImpact,
    required this.category,
    required this.difficulty,
    required this.xp,
    required this.progress,
    required this.completed,
    required this.questionIds,
    required this.tips,
  });

  factory PhishSimulation.fromJson(Map<String, dynamic> j) => PhishSimulation(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    threatType: j['threat_type'] ?? '',
    realImpact: j['real_impact'] ?? '',
    category: j['category'] ?? 'email',
    difficulty: j['difficulty'] ?? 'Fácil',
    xp: (j['xp'] as num?)?.toInt() ?? 0,
    progress: (j['progress'] as num?)?.toInt() ?? 0,
    completed: j['completed'] ?? false,
    questionIds: List<String>.from(j['question_ids'] ?? []),
    tips: List<String>.from(j['tips'] ?? []),
  );

  IconData get icon {
    switch (category) {
      case 'sms':
        return Icons.sms_outlined;
      case 'url':
        return Icons.link_outlined;
      case 'app':
        return Icons.apps_outlined;
      default:
        return Icons.mail_outline;
    }
  }

  Color get color {
    switch (category) {
      case 'sms':
        return AppColors.warn;
      case 'url':
        return AppColors.blue;
      case 'app':
        return AppColors.accent2;
      default:
        return AppColors.accent;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'Difícil':
        return AppColors.danger;
      case 'Médio':
        return AppColors.warn;
      default:
        return AppColors.accent;
    }
  }
}

class QuizOption {
  final String id;
  final String text;
  const QuizOption({required this.id, required this.text});
  factory QuizOption.fromJson(Map<String, dynamic> j) =>
      QuizOption(id: j['id'], text: j['text']);
}

class QuizQuestion {
  final String id;
  final String category;
  final String difficulty;
  final int points;
  final String scenario;
  final String clue;
  final List<QuizOption> options;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.points,
    required this.scenario,
    required this.clue,
    required this.options,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    id: j['id'],
    category: j['category'],
    difficulty: j['difficulty'],
    points: (j['points'] as num).toInt(),
    scenario: j['scenario'],
    clue: j['clue'],
    options: (j['options'] as List).map((o) => QuizOption.fromJson(o)).toList(),
    explanation: j['explanation'] ?? '',
  );

  String get categoryIcon {
    switch (category) {
      case 'sms':
        return '💬';
      case 'url':
        return '🔗';
      case 'app':
        return '📱';
      default:
        return '📧';
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'sms':
        return 'SMS';
      case 'url':
        return 'URL';
      case 'app':
        return 'App / QR';
      default:
        return 'E-mail';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'hard':
        return AppColors.danger;
      case 'medium':
        return AppColors.warn;
      default:
        return AppColors.accent;
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'hard':
        return 'Difícil';
      case 'medium':
        return 'Médio';
      default:
        return 'Fácil';
    }
  }
}
