import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService {
  static String get _base {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.238.20.68:8000';
  }

  static String get baseUrl => _base;

  static int currentUserId = 1;

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> _post(String path, Map body) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(
          String name, String email, String password) =>
      _post('/auth/register',
          {'name': name, 'email': email, 'password': password});

  static Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      _post('/auth/forgot-password', {'email': email});

  static Future<Map<String, dynamic>> verifyCode(String email, String code) =>
      _post('/auth/verify-code', {'email': email, 'code': code});

  static Future<Map<String, dynamic>> resetPassword(
          String email, String code, String newPassword) =>
      _post('/auth/reset-password',
          {'email': email, 'code': code, 'new_password': newPassword});

  static Future<List<dynamic>> getQuestions() async {
    final res = await http.get(Uri.parse('$_base/quiz/questions'));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> submitAnswer(
          String questionId, String optionId) =>
      _post('/quiz/answer', {
        'question_id': questionId,
        'selected_option_id': optionId,
        'user_id': currentUserId,
      });

  static Future<List<dynamic>> getSimulations() async {
    final res =
        await http.get(Uri.parse('$_base/simulations/?user_id=$currentUserId'));
    return jsonDecode(res.body);
  }

  static Future<void> updateSimulationProgress(
      String simId, int progress, bool completed) async {
    await _post('/simulations/$simId/progress', {
      'simulation_id': simId,
      'progress': progress,
      'completed': completed,
      'user_id': currentUserId,
    });
  }

  static Future<Map<String, dynamic>> getStats() =>
      _get('/stats/?user_id=$currentUserId');

  static Future<Map<String, dynamic>> addXp(
          int xp, bool correct, String category,
          {String scenario = ''}) =>
      _post('/stats/add-xp', {
        'xp': xp,
        'correct': correct,
        'category': category,
        'user_id': currentUserId,
        if (scenario.isNotEmpty) 'scenario': scenario,
      });

  static Future<List<dynamic>> getHistory() async {
    final res = await http
        .get(Uri.parse('$_base/stats/history?user_id=$currentUserId&limit=30'));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getRanking() async {
    final res = await http.get(Uri.parse('$_base/stats/ranking'));
    return jsonDecode(res.body);
  }

  static Future<void> deleteAccount(int userId) async {
    final res = await http.delete(
      Uri.parse('$_base/auth/delete-account/$userId'),
    );
    if (res.statusCode != 200) {
      throw Exception('Erro ao eliminar conta: ${res.statusCode}');
    }
  }

  static Future<void> updatePreferences({required bool showInRanking}) async {
    await http.post(
      Uri.parse('$_base/stats/preferences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': currentUserId,
        'show_in_ranking': showInRanking,
      }),
    );
  }

  static Future<String> sendChatMessage(
      String message, List<Map<String, String>> history) async {
    final res =
        await _post('/chat/message', {'message': message, 'history': history});
    return res['reply'] ?? 'Sem resposta.';
  }
}
