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
    final title = path
        .replaceAll('assets/lyrics/', '')
        .replaceAll('.md', '');

    String artist = '';
    String? key;
    int bodyStart = 0;

    // Parse metadata from first lines
    if (lines.isNotEmpty) {
      artist = lines.first.trim();
      bodyStart = 1;
    }
    if (lines.length > 1 && lines[1].trim().startsWith('Key:')) {
      key = lines[1].trim().replaceAll('Key:', '').trim();
      bodyStart = 2;
    }

    final lyrics = lines.skip(bodyStart).join('\n').trim();

    // Extract chords from lyrics lines
    final chordLines = <String>[];
    final lyricLines = <String>[];
    for (final line in lyrics.split('\n')) {
      final chords = RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug|add[0-9])?)\]').allMatches(line);
      if (chords.isNotEmpty) {
        final chordRow = StringBuffer();
        var lastEnd = 0;
        for (final m in chords) {
          chordRow.write(' ' * (m.start - lastEnd));
          chordRow.write(m.group(1)!);
          lastEnd = m.end;
        }
        chordLines.add(chordRow.toString());
        lyricLines.add(line.replaceAll(RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug|add[0-9])?)\]'), '').trim());
      } else {
        chordLines.add('');
        lyricLines.add(line);
      }
    }

    return LyricSong(
      title: title,
      artist: artist,
      key: key,
      lyrics: lyricLines.join('\n'),
      chords: chordLines,
    );
  }
}

class LyricSong {
  final String title;
  final String artist;
  final String? key;
  final String lyrics;
  final List<String> chords;

  const LyricSong({
    required this.title,
    required this.artist,
    this.key,
    required this.lyrics,
    this.chords = const [],
  });
}
