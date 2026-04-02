import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTab { dashboard, simulations, tips, ranking }

// ─── CORES DINÂMICAS (suportam light & dark mode) ────────────────────────────
class AppColors {
  AppColors._();

  // Valores mutáveis — alterados por apply()
  static Color bg = const Color(0xFF0F1318);
  static Color surface = const Color(0xFF1A2030);
  static Color surface2 = const Color(0xFF242D3E);
  static Color border = const Color(0x1AFFFFFF);
  static Color accent = const Color(0xFF00E5A0);
  static Color accentAlt = const Color(0xFF00C87A);
  static Color blue = const Color(0xFF818CF8);
  static Color warn = const Color(0xFFF59E0B);
  static Color danger = const Color(0xFFEF4444);
  static Color accent2 = const Color(0xFFF57C6B);
  static Color textMuted = const Color(0xFF64748B);
  static Color text = const Color(0xFFE2E8F0);

  /// Chama este método sempre que o tema mudar.
  static void apply(bool isDark) {
    if (isDark) {
      bg = const Color(0xFF0F1318);
      surface = const Color(0xFF1A2030);
      surface2 = const Color(0xFF242D3E);
      border = const Color(0x1AFFFFFF);
      text = const Color(0xFFE2E8F0);
      textMuted = const Color(0xFF64748B);
      accent = const Color(0xFF00E5A0);
      accentAlt = const Color(0xFF00C87A);
      blue = const Color(0xFF818CF8);
      warn = const Color(0xFFF59E0B);
      danger = const Color(0xFFEF4444);
      accent2 = const Color(0xFFF57C6B);
    } else {
      // ── LIGHT MODE — tons verdes-menta com fundo quente ──────────────────
      bg = const Color(0xFFF4F7F5); // fundo geral: branco com toque menta
      surface = const Color(0xFFFFFFFF); // cards brancos
      surface2 = const Color(0xFFEAF2EE); // destaque suave
      border = const Color(0xFFCDD9D4); // divisórias neutras
      text = const Color(0xFF0D1F1A); // texto escuro com toque verde
      textMuted = const Color(0xFF4B6858); // texto secundário esverdeado
      accent = const Color(
        0xFF00A374,
      ); // verde principal (mais escuro p/ contraste)
      accentAlt = const Color(0xFF008A62); // verde hover/press
      blue = const Color(0xFF6366F1);
      warn = const Color(0xFFD97706); // âmbar
      danger = const Color(0xFFDC2626); // vermelho
      accent2 = const Color(0xFFE04F3A); // coral
    }
  }
}

// ─── ROTAS ───────────────────────────────────────────────────────────────────
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

// ─── SESSÃO DO UTILIZADOR ────────────────────────────────────────────────────
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

// ─── PREFERÊNCIAS (tema, etc.) ───────────────────────────────────────────────
class AppPreferences {
  static late SharedPreferences _prefs;
  static final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final isDark = _prefs.getBool('isDarkMode') ?? true;
    AppColors.apply(isDark);
    themeNotifier.value = isDark;
  }

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('isDarkMode', value);
    AppColors.apply(value);
    themeNotifier.value = value;
  }

  static bool get isDarkMode => themeNotifier.value;

  // ── Aliases & extra prefs used by settings_screen ──────────────────────────
  /// Alias for isDarkMode (used by settings_screen)
  static bool get darkMode => themeNotifier.value;

  static bool get hapticEnabled => _prefs.getBool('hapticEnabled') ?? true;

  static bool get showXpAnimations =>
      _prefs.getBool('showXpAnimations') ?? true;

  static bool get showLeaderboard => _prefs.getBool('showLeaderboard') ?? true;

  static set showLeaderboard(bool v) => _prefs.setBool('showLeaderboard', v);

  static Future<void> setHaptic(bool v) async =>
      _prefs.setBool('hapticEnabled', v);

  static Future<void> setXpAnimations(bool v) async =>
      _prefs.setBool('showXpAnimations', v);

  static Future<void> setShowLeaderboard(bool v) async =>
      _prefs.setBool('showLeaderboard', v);
}

// ─── ESTATÍSTICAS DO UTILIZADOR ──────────────────────────────────────────────
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

// ─── HISTÓRICO ───────────────────────────────────────────────────────────────
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

// ─── RANKING ─────────────────────────────────────────────────────────────────
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

// ─── SIMULAÇÕES ──────────────────────────────────────────────────────────────
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

// ─── QUIZ ─────────────────────────────────────────────────────────────────────
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

// ─── MODELO DE CENÁRIO DE IA (ai_simulations) ─────────────────────────────────
class SuspiciousElement {
  final String id;
  final String label;
  final String hint;
  final bool isSuspicious;
  final String elementType;

  const SuspiciousElement({
    required this.id,
    required this.label,
    required this.hint,
    required this.isSuspicious,
    required this.elementType,
  });

  factory SuspiciousElement.fromJson(Map<String, dynamic> j) =>
      SuspiciousElement(
        id: j['id'] ?? '',
        label: j['label'] ?? '',
        hint: j['hint'] ?? '',
        isSuspicious: j['is_suspicious'] == true,
        elementType: j['element_type'] ?? 'body_text',
      );
}

class AiScenario {
  final String type;
  final bool isPhishing;
  final String difficulty;
  final String brand;
  final String brandColor;
  final String logoUrl;
  final String logoAltText;
  final String senderName;
  final String senderAddress;
  final String subject;
  final String previewText;
  final String body;
  final String ctaText;
  final String ctaUrl;
  final String timestamp;
  final String? phoneNumber;
  final String? pageTitle;
  final List<String> formFields;
  final List<SuspiciousElement> suspiciousElements;
  final List<String> redFlags;
  final List<String> greenFlags;
  final String explanation;
  final String attackTechnique;
  final String realWorldReference;
  final String potentialDamage;
  final String forensicTip;
  final String difficultyReason;

  const AiScenario({
    required this.type,
    required this.isPhishing,
    required this.difficulty,
    required this.brand,
    required this.brandColor,
    required this.logoUrl,
    required this.logoAltText,
    required this.senderName,
    required this.senderAddress,
    required this.subject,
    required this.previewText,
    required this.body,
    required this.ctaText,
    required this.ctaUrl,
    required this.timestamp,
    this.phoneNumber,
    this.pageTitle,
    required this.formFields,
    required this.suspiciousElements,
    required this.redFlags,
    required this.greenFlags,
    required this.explanation,
    required this.attackTechnique,
    required this.realWorldReference,
    required this.potentialDamage,
    required this.forensicTip,
    required this.difficultyReason,
  });

  factory AiScenario.fromJson(Map<String, dynamic> j) => AiScenario(
    type: j['type'] ?? 'email',
    isPhishing: j['is_phishing'] == true,
    difficulty: j['difficulty'] ?? 'medium',
    brand: j['brand'] ?? '',
    brandColor: j['brand_color'] ?? '#000000',
    logoUrl: j['logo_url'] ?? '',
    logoAltText: j['logo_alt_text'] ?? '',
    senderName: j['sender_name'] ?? '',
    senderAddress: j['sender_address'] ?? '',
    subject: j['subject'] ?? '',
    previewText: j['preview_text'] ?? '',
    body: j['body'] ?? '',
    ctaText: j['cta_text'] ?? '',
    ctaUrl: j['cta_url'] ?? '',
    timestamp: j['timestamp'] ?? '',
    phoneNumber: j['phone_number'],
    pageTitle: j['page_title'],
    formFields: List<String>.from(j['form_fields'] ?? []),
    suspiciousElements: (j['suspicious_elements'] as List? ?? [])
        .map((e) => SuspiciousElement.fromJson(e))
        .toList(),
    redFlags: List<String>.from(j['red_flags'] ?? []),
    greenFlags: List<String>.from(j['green_flags'] ?? []),
    explanation: j['explanation'] ?? '',
    attackTechnique: j['attack_technique'] ?? '',
    realWorldReference: j['real_world_reference'] ?? '',
    potentialDamage: j['potential_damage'] ?? '',
    forensicTip: j['forensic_tip'] ?? '',
    difficultyReason: j['difficulty_reason'] ?? '',
  );

  /// Parses [brandColor] hex string (e.g. "#FF0000") to a Flutter [Color].
  Color get brandColorParsed {
    try {
      final hex = brandColor.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return AppColors.accent;
  }

  /// Human-readable label for [type].
  String get typeLabel {
    switch (type) {
      case 'sms':
        return 'SMS';
      case 'url':
      case 'website':
        return 'Website';
      case 'call':
      case 'vishing':
        return 'Chamada';
      case 'qr':
        return 'QR Code';
      default:
        return 'E-mail';
    }
  }

  /// Human-readable label for [difficulty].
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

// ─── CASO FORENSE ─────────────────────────────────────────────────────────────
class ForensicCase {
  final String id;
  final String title;
  final String year;
  final String target;
  final String country;
  final String attackType;
  final String attackVector;
  final String emoji;
  // ignore: non_constant_identifier_names
  final String threat_actor;
  final String summary;
  final String howItWorked;
  final List<String> redFlags;
  final String outcome;
  final String financialImpact;
  final List<String> lessons;

  const ForensicCase({
    required this.id,
    required this.title,
    required this.year,
    required this.target,
    required this.country,
    required this.attackType,
    required this.attackVector,
    required this.emoji,
    required this.threat_actor,
    required this.summary,
    required this.howItWorked,
    required this.redFlags,
    required this.outcome,
    required this.financialImpact,
    required this.lessons,
  });
}
