import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/bible_search.dart';

class DailyVerseScreen extends StatefulWidget {
  const DailyVerseScreen({super.key});

  @override
  State<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends State<DailyVerseScreen>
    with SingleTickerProviderStateMixin {
  int _displayIndex = 0;
  late AnimationController _spinController;
  bool _isSpinning = false;
  bool _hasLanded = false;
  int _currentGradient = 0;
  int _rollCount = 0;
  final List<int> _shuffledOrder = [];
  int _shuffleIndex = 0;
  final _random = Random();

  // All verse references from the installed Bible
  late List<BibleSearchResult> _allVerses;

  static const _gradients = [
    [Color(0xFF1A1A2E), Color(0xFF16213E)],
    [Color(0xFF0F2027), Color(0xFF203A43)],
    [Color(0xFF2C1810), Color(0xFF4A2C1A)],
    [Color(0xFF1B1B2F), Color(0xFF2D1B69)],
    [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
    [Color(0xFF0D1B2A), Color(0xFF1B2838)],
    [Color(0xFF1C1410), Color(0xFF2C1A14)],
    [Color(0xFF0A0A1A), Color(0xFF1A1A3A)],
    [Color(0xFF1E2024), Color(0xFF2C3038)],
    [Color(0xFF121212), Color(0xFF1E1E2E)],
    [Color(0xFF0B132B), Color(0xFF1C2541)],
    [Color(0xFF1A0A2E), Color(0xFF2D1B4E)],
  ];

  @override
  void initState() {
    super.initState();

    // Pull from the installed Bible — never hardcoded
    _allVerses = BibleSearch.allVerses;
    if (_allVerses.isEmpty) {
      _allVerses = [BibleSearchResult(
        book: '', chapter: 0, verse: 0,
        text: 'No verses available yet.', matchType: '',
      )];
    }

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _spinController.addListener(() {
      final progress = _spinController.value;
      if (progress < 1.0) {
        final steps = (progress * 35).floor();
        final idx = steps % _allVerses.length;
        if (idx != _displayIndex) {
          setState(() => _displayIndex = idx);
        }
      }
    });

    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _hasLanded = true;
        });
      }
    });

    // Shuffle all verses — no repeats until all seen
    _shuffledOrder.addAll(
      List.generate(_allVerses.length, (i) => i)..shuffle(_random),
    );
    _displayIndex = _shuffledOrder[0];
    _currentGradient = _random.nextInt(_gradients.length);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _roll() {
    if (_isSpinning) return;

    _shuffleIndex++;
    if (_shuffleIndex >= _shuffledOrder.length) {
      _shuffledOrder.clear();
      _shuffledOrder.addAll(
        List.generate(_allVerses.length, (i) => i)..shuffle(_random),
      );
      _shuffleIndex = 0;
    }

    setState(() {
      _isSpinning = true;
      _hasLanded = false;
      _displayIndex = _shuffledOrder[_shuffleIndex];
      _currentGradient = _random.nextInt(_gradients.length);
      _rollCount++;
    });
    _spinController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final verse = _allVerses[_displayIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _isSpinning ? null : _roll,
        onLongPress: () => Navigator.pop(context),
        child: AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            final pulse = _isSpinning
                ? 1.0 + (0.02 * sin(_spinController.value * pi * 10))
                : _hasLanded
                    ? 1.0 + (0.012 * (1.0 - _spinController.value))
                    : 1.0;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradients[_currentGradient],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Top — just back button, nothing else
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back,
                            color: Colors.white.withAlpha(100)),
                          onPressed: () => Navigator.pop(context)),
                      ),
                    ),

                    // Main — quote
                    Expanded(
                      child: Transform.scale(
                        scale: pulse,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\u201C',
                                style: TextStyle(
                                  fontSize: 64,
                                  height: 0.4,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.white.withAlpha(
                                    _hasLanded ? 50 : 25),
                                ),
                              ),
                              const SizedBox(height: 8),

                              Text(
                                verse.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 21,
                                  height: 1.7,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withAlpha(
                                    _isSpinning ? 100 : 230),
                                  letterSpacing: 0.3,
                                ),
                              ),

                              const SizedBox(height: 24),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '\u201D',
                                    style: TextStyle(
                                      fontSize: 36,
                                      height: 0.3,
                                      fontWeight: FontWeight.w100,
                                      color: Colors.white.withAlpha(
                                        _hasLanded ? 40 : 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '\u2014 ${verse.reference}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: _hasLanded
                                          ? const Color(0xFFD4A843).withAlpha(200)
                                          : Colors.white.withAlpha(120),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom — counter + action
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          if (_isSpinning)
                            Text('searching...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withAlpha(60),
                                fontStyle: FontStyle.italic,
                              ))
                          else if (_hasLanded)
                            Column(
                              children: [
                                Text(
                                  '\u2666  $_rollCount  explored  \u2666',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withAlpha(50),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'tap to keep exploring',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(90),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'tap to discover',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withAlpha(70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
