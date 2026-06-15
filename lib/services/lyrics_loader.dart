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
    } catch (e) {
      debugPrint('LyricsLoader failed: $e');
    }
  }

  static LyricSong _parseSong(String path, String content) {
    final rawLines = content.split('\n');
    final title = path
        .replaceAll('assets/lyrics/', '')
        .replaceAll('.md', '');

    String artist = '';
    String? key;
    String? bpm;
    String? timeSig;
    int bodyStart = 0;

    // Parse metadata from the first lines
    if (rawLines.isNotEmpty) {
      artist = rawLines[0].trim();
      bodyStart = 1;
    }
    for (var i = 1; i < rawLines.length && i < 6; i++) {
      final line = rawLines[i].trim();
      if (line.startsWith('Key:')) {
        key = line.replaceAll('Key:', '').trim();
        bodyStart = i + 1;
      } else if (line.startsWith('BPM:')) {
        bpm = line.replaceAll('BPM:', '').trim();
        bodyStart = i + 1;
      } else if (line.startsWith('TimeSig:')) {
        timeSig = line.replaceAll('TimeSig:', '').trim();
        bodyStart = i + 1;
      }
    }

    // Join remaining lines for body parsing
    final body = rawLines.skip(bodyStart).join('\n').trim();

    // Parse lines: section markers [Verse], [Chorus], etc, chords [G], and lyrics
    final sections = <LyricSection>[];
    final chordLines = <String>[];
    final lyricLines = <String>[];
    String currentSection = '';

    for (final line in body.split('\n')) {
      final trimmed = line.trim();

      // Section marker?
      final sectionMatch = RegExp(r'^\[(Verse|Chorus|Bridge|Intro|Outro|Tag|Instrumental)(?:\s*\d*)?\]$', caseSensitive: false).firstMatch(trimmed);
      if (sectionMatch != null) {
        // Save previous section
        if (lyricLines.isNotEmpty) {
          sections.add(LyricSection(
            label: currentSection,
            lines: List.from(lyricLines),
            chords: List.from(chordLines),
          ));
          lyricLines.clear();
          chordLines.clear();
        }
        currentSection = sectionMatch.group(1)!;
        // Capitalize first letter
        currentSection = currentSection[0].toUpperCase() + currentSection.substring(1).toLowerCase();
        continue;
      }

      if (trimmed.isEmpty) continue;

      // Parse chords in the line
      final chordMatches = RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug|add[0-9])?)\]').allMatches(trimmed);
      if (chordMatches.isNotEmpty) {
        final chordRow = StringBuffer();
        var lastEnd = 0;
        for (final m in chordMatches) {
          chordRow.write(' ' * (m.start - lastEnd));
          chordRow.write(m.group(1)!);
          lastEnd = m.end;
        }
        chordLines.add(chordRow.toString());
        lyricLines.add(trimmed.replaceAll(RegExp(r'\[([A-G][#b]?m?(?:7|maj7|dim|sus|aug|add[0-9])?)\]'), '').trim());
      } else {
        chordLines.add('');
        lyricLines.add(trimmed);
      }
    }

    // Save last section
    if (lyricLines.isNotEmpty) {
      sections.add(LyricSection(
        label: currentSection,
        lines: List.from(lyricLines),
        chords: List.from(chordLines),
      ));
    }

    return LyricSong(
      title: title,
      artist: artist,
      key: key,
      bpm: bpm,
      timeSig: timeSig,
      sections: sections,
    );
  }
}

class LyricSection {
  final String label;
  final List<String> lines;
  final List<String> chords;
  const LyricSection({
    required this.label,
    required this.lines,
    this.chords = const [],
  });
}

class LyricSong {
  final String title;
  final String artist;
  final String? key;
  final String? bpm;
  final String? timeSig;
  final List<LyricSection> sections;

  const LyricSong({
    required this.title,
    required this.artist,
    this.key,
    this.bpm,
    this.timeSig,
    this.sections = const [],
  });
}
