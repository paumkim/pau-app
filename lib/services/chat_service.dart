import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

enum ChatModelType { ollama, huggingface, future }

class ChatService {
  static const _modelKey = 'selected_model';

  String _currentModel = 'Local (Laptop)';
  final Duration _timeout = const Duration(seconds: 120);
  http.Client? _activeRequest;

  Future<void> loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    _currentModel = prefs.getString(_modelKey) ?? 'Local (Laptop)';
  }

  String get currentModel => _currentModel;
  bool get isModelAvailable => _getModelDef()?.available ?? false;
  bool get isStreamable => _modelType == ChatModelType.ollama;

  ModelDef? _getModelDef() {
    try {
      return AppConfig.models.firstWhere((m) => m.name == _currentModel);
    } catch (_) {
      return null;
    }
  }

  ChatModelType get _modelType {
    if (_currentModel == 'Local (Laptop)') return ChatModelType.ollama;
    if (_currentModel == 'Qwen 1.5B (Better)') return ChatModelType.huggingface;
    return ChatModelType.future;
  }

  void cancelRequest() {
    _activeRequest?.close();
    _activeRequest = null;
  }

  /// Non-streaming chat for HF and fallback
  Future<String> chat(String message) async {
    if (!isModelAvailable) {
      return 'This model is not yet available. Training in progress.';
    }

    final prompt = _buildPrompt(message);

    try {
      switch (_modelType) {
        case ChatModelType.ollama:
          // Use streaming but collect full response
          final buffer = StringBuffer();
          await for (final chunk in chatStream(message)) {
            buffer.write(chunk);
          }
          final result = buffer.toString().trim();
          return result.isEmpty ? 'No response from model.' : result;
        case ChatModelType.huggingface:
          return await _chatHuggingFace(prompt);
        case ChatModelType.future:
          return 'This model is not yet available. Training in progress.';
      }
    } on TimeoutException {
      return 'Request timed out. Check your connection and try again.';
    } on http.ClientException catch (e) {
      return 'Cannot reach server: ${e.message}';
    } on SocketException catch (e) {
      return 'Connection refused: ${e.message}';
    } catch (e) {
      debugPrint('ChatService error: $e');
      return 'Something went wrong. Please try again.';
    }
  }

  /// Streaming chat — yields tokens as they arrive
  Stream<String> chatStream(String message) async* {
    if (!isModelAvailable) {
      yield 'This model is not yet available.';
      return;
    }

    if (_modelType != ChatModelType.ollama) {
      // Non-ollama models don't support streaming — yield full response
      final result = await chat(message);
      yield result;
      return;
    }

    final prompt = _buildPrompt(message);
    final url = await AppConfig.getOllamaUrl();
    final client = http.Client();
    _activeRequest = client;

    try {
      final request = http.Request('POST', Uri.parse(url))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({
          'model': AppConfig.ollamaModel,
          'prompt': prompt,
          'stream': true,
          'options': {
            'temperature': 0.3,
            'top_p': 0.9,
          },
        });

      final response = await client.send(request).timeout(_timeout);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        // Ollama sends one JSON object per line
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final data = jsonDecode(line);
            final token = data['response'] as String?;
            if (token != null) yield token;
            if (data['done'] == true) return;
          } catch (_) {
            // Skip malformed JSON lines
          }
        }
      }
    } finally {
      client.close();
      if (_activeRequest == client) _activeRequest = null;
    }
  }

  String _buildPrompt(String message) {
    return 'You are Pau, a helpful assistant for Zomi language speakers. '
        'If the user writes in English, respond in Zomi (Tedim). '
        'If the user writes in Zomi, respond in English. '
        'Keep responses natural and conversational. Answer briefly.\n\n'
        'User: $message\nAssistant:';
  }

  Future<String> _chatHuggingFace(String prompt) async {
    final token = AppConfig.hfToken;
    if (token.isEmpty) {
      return 'HF token not configured. Set HF_TOKEN at build time.';
    }

    final response = await http.post(
      Uri.parse(AppConfig.hfModelEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_new_tokens': 256,
          'temperature': 0.3,
          'top_p': 0.9,
          'do_sample': true,
          'return_full_text': false,
        },
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data[0]['generated_text'] as String;
      return text.trim();
    }
    return 'HF API error (${response.statusCode}).';
  }
}
