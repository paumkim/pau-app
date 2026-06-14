class Translation {
  final String id;
  final String sourceText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;
  bool isFavorite;

  Translation({
    String? id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    DateTime? timestamp,
    this.isFavorite = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceText': sourceText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'timestamp': timestamp.toIso8601String(),
        'isFavorite': isFavorite,
      };

  factory Translation.fromJson(Map<String, dynamic> json) => Translation(
        id: json['id'],
        sourceText: json['sourceText'],
        translatedText: json['translatedText'],
        sourceLanguage: json['sourceLanguage'],
        targetLanguage: json['targetLanguage'],
        timestamp: DateTime.parse(json['timestamp']),
        isFavorite: json['isFavorite'] ?? false,
      );
}
