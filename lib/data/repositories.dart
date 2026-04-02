import '../screen/api_service.dart';
// import '../models/app_models.dart'; // já importado pelo teu projecto

/// ─── Failure ─────────────────────────────────────────────────────────────────
/// Encapsula erros de domínio com mensagens legíveis para o utilizador.
class Failure implements Exception {
  final String message;
  final Object? cause;
  const Failure(this.message, {this.cause});

  @override
  String toString() => 'Failure: $message';
}

// ─── AuthRepository ──────────────────────────────────────────────────────────
/// Responsabilidade única: autenticação.
/// Não contém lógica de UI — apenas dados + transformação.

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      return await ApiService.login(email, password);
    } catch (e) {
      throw Failure(
        'Não foi possível iniciar sessão. Verifica a tua ligação.',
        cause: e,
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      await ApiService.register(name, email, password);
    } catch (e) {
      throw Failure('Erro ao criar conta. Tenta novamente.', cause: e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await ApiService.forgotPassword(email);
    } catch (e) {
      throw Failure('Não foi possível enviar o código.', cause: e);
    }
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      await ApiService.resetPassword(email, code, newPassword);
    } catch (e) {
      throw Failure('Erro ao redefinir a password.', cause: e);
    }
  }
}

// ─── StatsRepository ─────────────────────────────────────────────────────────
/// Responsabilidade única: estatísticas e XP do utilizador.

class StatsRepository {
  StatsRepository._();
  static final instance = StatsRepository._();

  /// Devolve as stats já parseadas.
  /// Lança [Failure] se a rede falhar.
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      return await ApiService.getStats();
    } catch (e) {
      throw Failure('Erro ao carregar estatísticas do servidor.', cause: e);
    }
  }

  Future<List<dynamic>> getHistory({int limit = 30}) async {
    try {
      return await ApiService.getHistory();
    } catch (e) {
      throw Failure('Erro ao carregar histórico.', cause: e);
    }
  }

  Future<List<dynamic>> getRanking() async {
    try {
      return await ApiService.getRanking();
    } catch (e) {
      throw Failure('Erro ao carregar ranking.', cause: e);
    }
  }

  Future<void> addXp(
    int xp,
    bool correct,
    String category, {
    String scenario = '',
  }) async {
    try {
      await ApiService.addXp(xp, correct, category, scenario: scenario);
    } catch (e) {
      // XP não crítico — não bloqueia UI, mas regista
      // ignore: avoid_print
      print('[StatsRepository] addXp falhou: $e');
    }
  }

  Future<void> updatePreferences({required bool showInRanking}) async {
    try {
      await ApiService.updatePreferences(showInRanking: showInRanking);
    } catch (e) {
      throw Failure('Erro ao guardar preferências.', cause: e);
    }
  }
}

// ─── SimulationRepository ────────────────────────────────────────────────────
/// Responsabilidade única: simulações e cenários.

class SimulationRepository {
  SimulationRepository._();
  static final instance = SimulationRepository._();

  Future<List<dynamic>> getSimulations() async {
    try {
      return await ApiService.getSimulations();
    } catch (e) {
      throw Failure('Erro ao carregar simulações.', cause: e);
    }
  }

  Future<void> updateProgress(
    String simId,
    int progress,
    bool completed,
  ) async {
    try {
      await ApiService.updateSimulationProgress(simId, progress, completed);
    } catch (e) {
      throw Failure('Erro ao guardar progresso.', cause: e);
    }
  }

  Future<Map<String, dynamic>> generateAiSimulation({
    String? type,
    String? difficulty,
    bool? isPhishing,
  }) async {
    try {
      return await ApiService.generateAiSimulation(
        type: type,
        difficulty: difficulty,
        isPhishing: isPhishing,
      );
    } catch (e) {
      throw Failure('Erro ao gerar simulação com IA.', cause: e);
    }
  }

  Future<Map<String, dynamic>> getAdvancedSim(String simType) async {
    try {
      return await ApiService.getAdvancedSim(simType);
    } catch (e) {
      throw Failure('Erro ao carregar simulação avançada.', cause: e);
    }
  }

  Future<Map<String, dynamic>> submitAdvancedSimAnswer(
    String simType,
    String simId,
    bool isPhishing, {
    int? timeSeconds,
  }) async {
    try {
      return await ApiService.submitAdvancedSimAnswer(
        simType,
        simId,
        isPhishing,
        timeSeconds: timeSeconds,
      );
    } catch (e) {
      throw Failure('Erro ao submeter resposta.', cause: e);
    }
  }
}

// ─── ChatRepository ───────────────────────────────────────────────────────────
/// Responsabilidade única: chat com o assistente IA.

class ChatRepository {
  ChatRepository._();
  static final instance = ChatRepository._();

  Future<String> sendMessage(
    String message,
    List<Map<String, String>> history,
  ) async {
    try {
      return await ApiService.sendChatMessage(message, history);
    } catch (e) {
      throw Failure('Não foi possível contactar o assistente.', cause: e);
    }
  }
}
