import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/lyrics_loader.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricSong> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(LyricsLoader.songs);
    _loading = false;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = List.from(LyricsLoader.songs);
      } else {
        final query = q.toLowerCase();
        _filtered = LyricsLoader.songs.where((s) =>
          s.title.toLowerCase().contains(query) ||
          s.artist.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                Text('Zomi Lyrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${LyricsLoader.songs.length} songs',
                  style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { _searchCtrl.clear(); _search(''); },
                      )
                    : null,
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                              size: 40, color: AppTheme.textSecondaryLight.withAlpha(80)),
                            const SizedBox(height: 12),
                            Text('No songs found',
                              style: TextStyle(color: AppTheme.textSecondaryLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final song = _filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.accent.withAlpha(25),
                                child: Icon(Icons.music_note,
                                  color: AppTheme.accent, size: 18),
                              ),
                              title: Text(song.title,
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: Text(song.artist,
                                style: const TextStyle(fontSize: 12)),
                              trailing: const Icon(Icons.play_circle_outline, size: 20),
                              onTap: () => _showLyrics(context, song),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsWithChords(LyricSong song) {
    final lines = song.lyrics.split('\n');
    final hasChords = song.chords.length == lines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (i) {
        final chordLine = hasChords && i < song.chords.length ? song.chords[i] : '';
        final lyricLine = lines[i];

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chordLine.isNotEmpty)
                Text(chordLine,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                    fontFamily: 'monospace',
                    height: 1.2,
                  )),
              Text(lyricLine,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white : Colors.black87,
                )),
            ],
          ),
        );
      }),
    );
  }

  void _showLyrics(BuildContext context, LyricSong song) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(10),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                        Text(song.artist,
                          style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondaryLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildLyricsWithChords(song),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
