import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig._();

  static const String version = '1.0.1+2';

  // Default Ollama endpoint (user-configurable via Settings)
  static const String defaultOllamaHost = '192.168.12.189';
  static const int defaultOllamaPort = 11434;

  // Hugging Face — use dart-define at build time, never hardcode
  static String get hfToken {
    const token = String.fromEnvironment('HF_TOKEN');
    if (token.isNotEmpty) return token;
    debugPrint('WARNING: No HF_TOKEN set via --dart-define. Using placeholder.');
    return '';
  }

  static const String hfModelEndpoint =
      'https://router.huggingface.co/hf-inference/models/Qwen/Qwen2.5-1.5B-Instruct';

  // DeepSeek — set via dart-define: DEEPSEEK_TOKEN
  static String get deepSeekToken {
    const token = String.fromEnvironment('DEEPSEEK_TOKEN');
    return token;
  }

  static const String cloudApiBase = 'https://api.pau.app/v1';

  // Placeholder endpoints (not yet active)
  static const String futureChatEndpoint = 'https://api.pau.app/v1/chat';

  static const String ollamaModel = 'qwen2.5:0.5b';

  static Future<String> getOllamaUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ollama_host') ?? defaultOllamaHost;
    final port = prefs.getInt('ollama_port') ?? defaultOllamaPort;
    return 'http://$host:$port/api/generate';
  }

  static Future<void> setOllamaEndpoint(String host, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ollama_host', host);
    await prefs.setInt('ollama_port', port);
  }

  // Model definitions — with availability status
  static const List<ModelDef> models = [
    ModelDef('Local (Laptop)', 'qwen2.5:0.5b on your laptop', available: true),
    ModelDef('Qwen 1.5B (Better)', 'Hugging Face Inference API', available: true),
    ModelDef('Pau Zomi (Soon)', 'Fine-tuned model (training in progress)', available: false),
  ];
}

class ModelDef {
  final String name;
  final String description;
  final bool available;

  const ModelDef(this.name, this.description, {this.available = true});
}
