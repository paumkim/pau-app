import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loads Zomi worship lyrics from .md files in assets/lyrics/.
/// Each .md file = one song.
/// Filename format: "Song Title.md"
/// Content: first line = artist, rest = lyrics
class LyricsLoader {
  static List<LyricSong> _songs = [];

  static List<LyricSong> get songs => List.unmodifiable(_songs);

  static Future<void> loadAll() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final paths = jsonDecode(manifest).keys.where(
        (p) => p.startsWith('assets/lyrics/') && p.endsWith('.md'),
      );

      _songs = [];
      for (final path in paths) {
        try {
          final content = await rootBundle.loadString(path);
          final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
          if (lines.isEmpty) continue;

          final artist = lines.first.trim();
          final lyrics = lines.skip(1).join('\n').trim();
          if (lyrics.isEmpty) continue;

          // Extract title from filename: "assets/lyrics/Song Title.md" → "Song Title"
          final title = path
              .replaceAll('assets/lyrics/', '')
              .replaceAll('.md', '');

          _songs.add(LyricSong(title: title, artist: artist, lyrics: lyrics));
        } catch (_) {}
      }

      // Sort alphabetically by title
      _songs.sort((a, b) => a.title.compareTo(b.title));
      debugPrint('LyricsLoader: ${_songs.length} songs loaded');
    } catch (e) {
      debugPrint('LyricsLoader failed: $e');
    }
  }
}

class LyricSong {
  final String title;
  final String artist;
  final String lyrics;
  const LyricSong({
    required this.title,
    required this.artist,
    required this.lyrics,
  });
}
