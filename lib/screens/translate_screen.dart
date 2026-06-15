import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../services/hive_storage.dart';
import '../services/storage_service.dart';
import '../models/translation.dart';
import '../config/globals.dart';
import '../widgets/error_widgets.dart';
import '../widgets/keyboard_dismiss.dart';

class TranslateScreen extends StatefulWidget {
  final String? initialSource;
  final String? initialTarget;
  const TranslateScreen({super.key, this.initialSource, this.initialTarget});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final _textController = TextEditingController();
  final _translationService = TranslationService();
  final _storageService = StorageService();
  String _sourceLanguage = 'zomi';
  String _targetLanguage = 'en';
  String _translatedText = '';
  bool _isTranslating = false;
  String? _errorMessage;

  final List<_Language> _languages = [
    _Language('zomi', 'Zomi'),
    _Language('en', 'English'),
    _Language('ms', 'Bahasa Melayu'),
    _Language('zh', '中文'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSource != null) _sourceLanguage = widget.initialSource!;
    if (widget.initialTarget != null) _targetLanguage = widget.initialTarget!;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
      _translatedText = '';
      _errorMessage = null;
    });
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _errorMessage = null;
    });

    final result = await _translationService.translate(
      text: text,
      source: _sourceLanguage,
      target: _targetLanguage,
    );

    if (mounted) {
      setState(() {
        _translatedText = result.text;
        _isTranslating = false;
        if (!result.success) {
          _errorMessage = result.error;
        } else if (result.error != null) {
          _errorMessage = result.error;
        }
      });

      if (result.success) {
        _storageService.saveTranslation(Translation(
          sourceText: text,
          translatedText: result.text,
          sourceLanguage: _sourceLanguage,
          targetLanguage: _targetLanguage,
        ));
        if (HiveStorage.isAvailable) {
          HiveStorage.saveTranslation({
            'sourceText': text,
            'translatedText': result.text,
            'sourceLanguage': _sourceLanguage,
            'targetLanguage': _targetLanguage,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }

  void _copyTranslation() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = connectivityService.isOffline;

    return Scaffold(
      body: KeyboardDismiss(child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isOffline)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text('You\'re offline. Showing cached content.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                      ],
                    ),
                  ),
                _buildLanguageRow(isNarrow),
                const SizedBox(height: 16),

                TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type or paste text...',
                    contentPadding: const EdgeInsets.all(14),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _textController.clear();
                              setState(() {
                                _translatedText = '';
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    if (!isNarrow)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.mic, size: 18),
                          label: const Text('Voice'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voice input coming soon'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    if (!isNarrow) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.translate, size: 18),
                        label: Text(
                          isOffline ? 'Offline' : _isTranslating ? 'Translating...' : 'Translate'),
                        onPressed: _isTranslating || isOffline ? null : _translate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null && _translatedText.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppErrorWidget(
                      message: _errorMessage!,
                      icon: Icons.translate,
                      onRetry: _translate,
                    ),
                  ),

                if (_translatedText.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('Translation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600)),
                      const Spacer(),
                      _smallAction(Icons.copy, 'Copy', _copyTranslation),
                      _smallAction(Icons.favorite_border, 'Save', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved'),
                            duration: Duration(seconds: 1)),
                        );
                      }),
                      _smallAction(Icons.volume_up, 'Listen', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Text-to-speech coming soon'),
                            duration: Duration(seconds: 1)),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SelectableText(
                      _translatedText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_errorMessage!,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildLanguageRow(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: _LanguageDropdown(
            label: 'From',
            value: _sourceLanguage,
            languages: _languages,
            narrow: isNarrow,
            onChanged: (v) => setState(() => _sourceLanguage = v!),
          ),
        ),
        GestureDetector(
          onTap: _swapLanguages,
          child: Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.swap_vert, size: 18,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100)),
          ),
        ),
        Expanded(
          child: _LanguageDropdown(
            label: 'To',
            value: _targetLanguage,
            languages: _languages,
            narrow: isNarrow,
            onChanged: (v) => setState(() => _targetLanguage = v!),
          ),
        ),
      ],
    );
  }

  Widget _smallAction(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: const EdgeInsets.all(6),
    );
  }
}

class _Language {
  final String code;
  final String name;
  const _Language(this.code, this.name);
}

class _LanguageDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<_Language> languages;
  final bool narrow;
  final ValueChanged<String?> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.value,
    required this.languages,
    required this.narrow,
    required this.onChanged,
  });

  static Widget _flag(String code) {
    switch (code) {
      case 'zomi':
        return Image.asset('assets/icons/zomi_flag.png', width: 22, height: 16,
          errorBuilder: (_, __, ___) => _simpleFlag(code));
      case 'en':
        return _simpleFlag('en');
      case 'ms':
        return _simpleFlag('ms');
      case 'zh':
        return _simpleFlag('zh');
      default:
        return const Icon(Icons.flag, size: 16);
    }
  }

  static Widget _simpleFlag(String code) {
    switch (code) {
      case 'en':
        return Container(
          width: 22, height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Stack(
            children: [
              // Blue field
              Container(color: const Color(0xFF012169)),
              // Red cross (vertical) — St Patrick
              Center(
                child: Container(width: 6, height: 16, color: Colors.white),
              ),
              Center(
                child: Container(width: 3, height: 16, color: const Color(0xFFCE1124)),
              ),
              // Red cross (horizontal) — St George
              Center(
                child: Container(width: 22, height: 6, color: Colors.white),
              ),
              Center(
                child: Container(width: 22, height: 3, color: const Color(0xFFCE1124)),
              ),
            ],
          ),
        );
      case 'ms':
        return Container(
          width: 22, height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Stack(
            children: [
              Column(
                children: List.generate(14, (i) => Expanded(
                  child: Container(
                    color: i.isEven ? const Color(0xFFCC0000) : Colors.white,
                  ),
                )),
              ),
              // Blue canton
              Positioned(
                left: 0, top: 0,
                child: Container(
                  width: 10, height: 8,
                  color: const Color(0xFF010066),
                  child: Stack(
                    children: [
                      // Crescent (approximate with overlapping circles)
                      Center(
                        child: Container(
                          width: 6, height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCC00),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 1, top: 2,
                        child: Container(
                          width: 3, height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF010066),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 'zh':
        return Container(
          width: 22, height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: const Color(0xFFDE2910),
          ),
          child: Stack(
            children: [
              // One large star
              Positioned(
                left: 3, top: 3,
                child: Icon(Icons.star, size: 7, color: const Color(0xFFFFDE00)),
              ),
              // Four small stars
              Positioned(
                left: 8, top: 2,
                child: Icon(Icons.star, size: 3, color: const Color(0xFFFFDE00)),
              ),
              Positioned(
                left: 9, top: 5,
                child: Icon(Icons.star, size: 3, color: const Color(0xFFFFDE00)),
              ),
              Positioned(
                left: 9, top: 8,
                child: Icon(Icons.star, size: 3, color: const Color(0xFFFFDE00)),
              ),
              Positioned(
                left: 8, top: 11,
                child: Icon(Icons.star, size: 3, color: const Color(0xFFFFDE00)),
              ),
            ],
          ),
        );
      default:
        return const Icon(Icons.flag, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10, vertical: narrow ? 6 : 10),
          ),
          items: languages.map((l) {
            return DropdownMenuItem(
              value: l.code,
              child: Row(
                children: [
                  _flag(l.code),
                  const SizedBox(width: 8),
                  Text(l.name, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
