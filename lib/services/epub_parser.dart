import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import '../models/book_content.dart';

class EpubParser {
  /// Opens and parses an EPUB file.
  /// Automatically runs on a background isolate on non-web platforms.
  static Future<BookContent?> openFile(String filePath) async {
    // Use compute to run parsing on background isolate
    // This prevents UI freezes on large EPUBs
    try {
      if (kIsWeb) {
        return _parseEpub(filePath);
      }
      return await compute(_parseEpub, filePath);
    } catch (e) {
      debugPrint('EpubParser error: $e');
      return null;
    }
  }

  static BookContent? _parseEpub(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find OPF via META-INF/container.xml
      String? opfPath;
      try {
        final containerXml = utf8.decode(
          archive.firstWhere((f) => f.name == 'META-INF/container.xml').content,
        );
        final opfMatch = RegExp(r'full-path="([^"]+)"').firstMatch(containerXml);
        if (opfMatch != null) opfPath = opfMatch.group(1);
      } catch (_) {
        for (var f in archive) {
          if (f.name.endsWith('.opf')) { opfPath = f.name; break; }
        }
      }
      if (opfPath == null) return null;

      // Parse OPF
      final opfDir = opfPath.contains('/')
          ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1)
          : '';
      final opfContent = utf8.decode(
        archive.firstWhere((f) => f.name == opfPath).content);

      String title = 'Untitled';
      final tMatch = RegExp(r'<dc:title[^>]*>([^<]+)</dc:title>',
        caseSensitive: false).firstMatch(opfContent);
      if (tMatch != null) title = tMatch.group(1)!;

      String author = '';
      final aMatch = RegExp(r'<dc:creator[^>]*>([^<]+)</dc:creator>',
        caseSensitive: false).firstMatch(opfContent);
      if (aMatch != null) author = aMatch.group(1)!;

      // Build ID-to-href map from manifest
      final idToHref = <String, String>{};
      for (var m in RegExp(
        r'<item[^>]*id="([^"]+)"[^>]*href="([^"]+)"[^>]*media-type="application/xhtml\+xml"[^>]*>',
        caseSensitive: false,
      ).allMatches(opfContent)) {
        idToHref[m.group(1)!] = m.group(2)!;
      }

      // Get ordered reading list from spine
      final spineOrder = <String>[];
      for (var m in RegExp(
        r'<itemref[^>]*idref="([^"]+)"', caseSensitive: false,
      ).allMatches(opfContent)) {
        final id = m.group(1)!;
        if (idToHref.containsKey(id)) spineOrder.add(idToHref[id]!);
      }

      if (spineOrder.isEmpty) return null;

      // Parse each HTML file
      final sections = <BookSection>[];
      for (var href in spineOrder) {
        try {
          final fullPath = opfDir + href;
          final htmlFile = archive.firstWhere((f) => f.name == fullPath);
          final html = utf8.decode(htmlFile.content);
          final text = _stripHtml(html);
          if (text.trim().length < 20) continue;

          final lines = text.trim().split('\n')
              .where((l) => l.trim().isNotEmpty).toList();
          final sectionTitle = lines.isNotEmpty
              ? lines.first.trim()
              : 'Page ${sections.length + 1}';
          final content = lines.length > 1
              ? lines.skip(1).join('\n')
              : '';

          sections.add(BookSection(
            title: sectionTitle.length > 100
                ? sectionTitle.substring(0, 100)
                : sectionTitle,
            chapters: [
              BookChapter(
                number: sections.length + 1,
                content: content.isNotEmpty ? content : sectionTitle,
              )
            ],
          ));
        } catch (_) {}
      }

      if (sections.isEmpty) return null;

      return BookContent(
        id: filePath.split('/').last.replaceAll('.epub', ''),
        title: title,
        author: author,
        subtitle: author.isNotEmpty ? 'by $author' : '',
        sections: sections,
      );
    } catch (e) {
      debugPrint('EPUB parse failed: $e');
      return null;
    }
  }

  static String _stripHtml(String html) {
    html = html.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>',
        dotAll: true, caseSensitive: false), '');
    html = html.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>',
        dotAll: true, caseSensitive: false), '');
    html = html.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');
    html = html.replaceAll(
      RegExp(r'</(p|div|h[1-6]|blockquote|li|dd|dt)>',
        caseSensitive: false), '\n');
    html = html.replaceAll(RegExp(r'<[^>]+>'), '');
    html = html.replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    return html.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');
  }
}
