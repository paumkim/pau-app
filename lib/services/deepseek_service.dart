import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class DeepSeekService {
  static const _baseUrl = 'https://api.deepseek.com/v1/chat/completions';

  /// Stream a coding conversation with DeepSeek.
  /// Uses the same model you're already using in your chat.
  Stream<String> chat({
    required List<Map<String, String>> messages,
    String model = 'deepseek-chat',
  }) async* {
    final token = AppConfig.deepSeekToken;
    if (token.isEmpty) {
      yield 'DeepSeek token not configured. Set DEEPSEEK_TOKEN at build time.';
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'stream': true,
          'max_tokens': 4096,
        }),
      ).timeout(const Duration(seconds: 120));

      // Parse SSE stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'] as String?;
              if (content != null) yield content;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }
}
