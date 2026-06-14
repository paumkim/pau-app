import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/book_content.dart';

class BookRegistry {
  static final List<BookContent> _books = [];

  static List<BookContent> get books => List.unmodifiable(_books);

  static Future<void> loadAll() async {
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final paths = jsonDecode(manifest).keys.where((p) => p.startsWith('assets/books/') && p.endsWith('.json'));

    for (var path in paths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        _books.add(_parseBook(data));
      } catch (e) {
        // skip invalid books
      }
    }
  }

  static BookContent _parseBook(Map<String, dynamic> data) {
    return BookContent(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      subtitle: data['subtitle'] as String? ?? '',
      author: data['author'] as String? ?? '',
      sections: (data['sections'] as List?)?.map((s) {
        final sec = s as Map<String, dynamic>;
        return BookSection(
          title: sec['title'] as String? ?? '',
          chapters: (sec['chapters'] as List?)?.map((c) {
            final ch = c as Map<String, dynamic>;
            return BookChapter(
              number: ch['number'] as int? ?? 1,
              content: ch['content'] as String? ?? '',
            );
          }).toList() ?? [],
        );
      }).toList() ?? [],
    );
  }
}
