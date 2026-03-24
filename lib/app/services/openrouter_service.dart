import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:soul_matcher/app/core/constants/openrouter_config.dart';

class OpenRouterService {
  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<String?> generateDemoReply({
    required String personaName,
    required String userMessage,
  }) async {
    if (!OpenRouterConfig.isConfigured) {
      return null;
    }

    final Uri url = Uri.parse('${OpenRouterConfig.baseUrl}/chat/completions');
    final String safePersona = personaName.trim().isEmpty
        ? 'SoulMatch partner'
        : personaName.trim();
    final String prompt = userMessage.trim();
    if (prompt.isEmpty) return null;

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OpenRouterConfig.model,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'system',
          'content':
              'You are $safePersona on a dating app. Reply naturally, warm tone, 1-2 short sentences, no markdown.',
        },
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.8,
      'max_tokens': 80,
    };

    final http.Response response = await http
        .post(
          url,
          headers: <String, String>{
            'Authorization': 'Bearer ${OpenRouterConfig.apiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://soulmatcher.app',
            'X-Title': 'Soul Matcher Demo Reply',
          },
          body: jsonEncode(payload),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final dynamic choices = body['choices'];
    if (choices is! List || choices.isEmpty) return null;

    final dynamic message = choices.first['message'];
    if (message is! Map<String, dynamic>) return null;

    final dynamic content = message['content'];
    if (content is String) {
      final String reply = content.trim();
      return reply.isEmpty ? null : reply;
    }

    if (content is List) {
      final String combined = content
          .map((dynamic part) {
            if (part is Map<String, dynamic>) {
              return part['text']?.toString() ?? '';
            }
            return '';
          })
          .join(' ')
          .trim();
      return combined.isEmpty ? null : combined;
    }

    return null;
  }
}
