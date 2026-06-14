import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final List<Map<String, String>> _songs = [
    {'title': 'Pasian Tunga', 'artist': 'Zomi Worship', 'lyrics': _pasianTunga},
    {'title': 'Ka Khua Ah', 'artist': 'Zomi Worship', 'lyrics': _kaKhuaAh},
    {'title': 'Nang Mah Bang', 'artist': 'Zomi Worship', 'lyrics': _nangMahBang},
    {'title': 'Itna Thupha', 'artist': 'Zomi Worship', 'lyrics': _itnaThupha},
    {'title': 'Topa Ka Ngai', 'artist': 'Zomi Worship', 'lyrics': _topaKaNgai},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
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
                Text('${_songs.length} songs',
                  style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accent.withAlpha(25),
                      child: Icon(Icons.music_note,
                        color: AppTheme.accent, size: 18),
                    ),
                    title: Text(song['title']!,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(song['artist']!,
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

  void _showLyrics(BuildContext context, Map<String, String> song) {
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
                        Text(song['title']!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600)),
                        Text(song['artist']!,
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
                child: Text(
                  song['lyrics'] ?? 'Lyrics coming soon.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.8),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

const _pasianTunga = '''Pasian tunga, Pasian tunga,
Ka kha in Pasian tunga a nungta;
Ama' tawh a kikhel lo,
A tawntung nuntakna ka ngah hi.''';

const _kaKhuaAh = '''Ka khua ah, ka khua ah,
Nangmah thu-um mi khempeuh in
Nangma lam et uh hi;
Ka khua ah, ka khua ah,
Pasian' mite in nang lam et uh hi.''';

const _nangMahBang = '''Nang mah bang om lo,
Pasian in hong piak khempeuh ah;
Nang mah bang om lo,
Ka kha in thuak nuam mah mah hi.''';

const _itnaThupha = '''Itna thupha, itna thupha,
Pasian in hong pia a itna;
Ama' tapa a upa maimai in
Nun tawntung i ngah theih nading hi.''';

const _topaKaNgai = '''Topa ka ngai, Topa ka ngai,
Ka kha in nang lam et hi;
Nang tawh ka om ding,
Tuuni panin kum khat dongin.''';
