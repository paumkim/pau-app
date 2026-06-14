import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
          _songs.add(_parseSong(path, content));
        } catch (_) {}
      }
      _songs.sort((a, b) => a.title.compareTo(b.title));
      debugPrint('LyricsLoader: ${_songs.length} songs loaded');
    } catch (e) {
      debugPrint('LyricsLoader failed: $e');
    }
  }

  static LyricSong _parseSong(String path, String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final artist = lines.isNotEmpty ? lines.first.trim() : '';
    final lyrics = lines.skip(1).join('\n').trim();
    final title = path
        .replaceAll('assets/lyrics/', '')
        .replaceAll('.md', '');

    // Extract chords from lyrics lines
    final chordLines = <String>[];
    final lyricLines = <String>[];
    for (final line in lyrics.split('\n')) {
      final chords = RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug)?)\]').allMatches(line);
      if (chords.isNotEmpty) {
        // Build a chord row from the matches
        final chordRow = StringBuffer();
        var lastEnd = 0;
        for (final m in chords) {
          chordRow.write(' ' * (m.start - lastEnd));
          chordRow.write(m.group(1)!);
          lastEnd = m.end;
        }
        chordLines.add(chordRow.toString());
        // Remove chord markers for lyric display
        lyricLines.add(line.replaceAll(RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug)?)\]'), '').trim());
      } else {
        chordLines.add('');
        lyricLines.add(line);
      }
    }

    return LyricSong(
      title: title,
      artist: artist,
      lyrics: lyricLines.join('\n'),
      chords: chordLines,
    );
  }
}

class LyricSong {
  final String title;
  final String artist;
  final String lyrics;
  final List<String> chords;

  const LyricSong({
    required this.title,
    required this.artist,
    required this.lyrics,
    this.chords = const [],
  });
}
