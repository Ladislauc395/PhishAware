enum QuestionType { email, sms, url, app }

enum Difficulty { easy, medium, hard }

enum AnswerType { legit, phishing }

class Question {
  final int id;
  final QuestionType type;
  final Difficulty difficulty;
  final AnswerType correctAnswer;
  final String scenario;
  final QuestionContent content;
  final String explanation;
  final String clue;

  const Question({
    required this.id,
    required this.type,
    required this.difficulty,
    required this.correctAnswer,
    required this.scenario,
    required this.content,
    required this.explanation,
    required this.clue,
  });

  int get points {
    switch (difficulty) {
      case Difficulty.easy:
        return 10;
      case Difficulty.medium:
        return 20;
      case Difficulty.hard:
        return 30;
    }
  }

  String get typeLabel {
    switch (type) {
      case QuestionType.email:
        return 'E-mail';
      case QuestionType.sms:
        return 'SMS';
      case QuestionType.url:
        return 'URL';
      case QuestionType.app:
        return 'App / QR';
    }
  }

  String get typeIcon {
    switch (type) {
      case QuestionType.email:
        return '📧';
      case QuestionType.sms:
        return '💬';
      case QuestionType.url:
        return '🔗';
      case QuestionType.app:
        return '📱';
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Fácil';
      case Difficulty.medium:
        return 'Médio';
      case Difficulty.hard:
        return 'Difícil';
    }
  }
}

class QuestionContent {
  final ContentType contentType;
  final EmailContent? emailContent;
  final SmsContent? smsContent;
  final UrlContent? urlContent;
  final AppContent? appContent;

  const QuestionContent.email(EmailContent content)
    : contentType = ContentType.email,
      emailContent = content,
      smsContent = null,
      urlContent = null,
      appContent = null;

  const QuestionContent.sms(SmsContent content)
    : contentType = ContentType.sms,
      smsContent = content,
      emailContent = null,
      urlContent = null,
      appContent = null;

  const QuestionContent.url(UrlContent content)
    : contentType = ContentType.url,
      urlContent = content,
      emailContent = null,
      smsContent = null,
      appContent = null;

  const QuestionContent.app(AppContent content)
    : contentType = ContentType.app,
      appContent = content,
      emailContent = null,
      smsContent = null,
      urlContent = null;
}

enum ContentType { email, sms, url, app }

class EmailContent {
  final String from;
  final String to;
  final String subject;
  final String body;
  final String? link;

  const EmailContent({
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    this.link,
  });
}

class SmsContent {
  final String sender;
  final String body;
  final String? link;

  const SmsContent({required this.sender, required this.body, this.link});
}

class UrlContent {
  final String url;
  final bool hasLock;
  final String? note;
  final List<UrlSegment> segments;

  const UrlContent({
    required this.url,
    this.hasLock = true,
    this.note,
    this.segments = const [],
  });
}

class UrlSegment {
  final String text;
  final bool isDangerous;
  const UrlSegment(this.text, {this.isDangerous = false});
}

class AppContent {
  final String title;
  final String description;
  final bool isMalicious;

  const AppContent({
    required this.title,
    required this.description,
    this.isMalicious = false,
  });
}
