import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'privacy_screen.dart';
import '../config/globals.dart';
import '../config/app_config.dart';
import '../services/translation_cache.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticOn = true;
  String _currentModel = AppConfig.models.first.name;
  String _ollamaHost = AppConfig.defaultOllamaHost;
  int _ollamaPort = AppConfig.defaultOllamaPort;
  int _cacheCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCacheCount();
  }

  Future<void> _loadCacheCount() async {
    final count = await TranslationCache.count;
    if (mounted) setState(() => _cacheCount = count);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hapticOn = prefs.getBool('haptic_feedback') ?? true;
      _currentModel = prefs.getString('selected_model') ?? AppConfig.models.first.name;
      _ollamaHost = prefs.getString('ollama_host') ?? AppConfig.defaultOllamaHost;
      _ollamaPort = prefs.getInt('ollama_port') ?? AppConfig.defaultOllamaPort;
    });
  }

  void _showModelPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose AI Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConfig.models.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.name),
              subtitle: Text(entry.description),
              value: entry.name,
              groupValue: _currentModel,
              activeColor: entry.available ? AppTheme.primary : AppTheme.textSecondaryLight,
              onChanged: entry.available ? (v) async {
                if (v != null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_model', v);
                  setState(() => _currentModel = v);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _snack('Switched to $v');
                }
              } : null,
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showOllamaConfig(BuildContext context) {
    final hostController = TextEditingController(text: _ollamaHost);
    final portController = TextEditingController(text: _ollamaPort.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ollama Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                labelText: 'Host / IP Address',
                hintText: 'e.g. 192.168.12.189',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'e.g. 11434',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final host = hostController.text.trim();
            final port = int.tryParse(portController.text.trim()) ?? 11434;
            await AppConfig.setOllamaEndpoint(host, port);
            setState(() {
              _ollamaHost = host;
              _ollamaPort = port;
            });
            if (ctx.mounted) Navigator.pop(ctx);
            _snack('Ollama endpoint updated');
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.settings, size: 32, color: AppTheme.primary),
                ),
                const SizedBox(height: 12),
                Text('Pau',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Your Zomi language companion',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _section(context, 'AI & Server', [
            _tile(
              icon: Icons.auto_awesome,
              iconColor: AppTheme.primary,
              title: 'AI Model',
              subtitle: _currentModel,
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _showModelPicker(context),
            ),
            _tile(
              icon: Icons.dns_outlined,
              title: 'Ollama Server',
              subtitle: '$_ollamaHost:$_ollamaPort',
              trailing: const Icon(Icons.edit, size: 16),
              onTap: () => _showOllamaConfig(context),
            ),
            _tile(
              icon: Icons.wifi_off_outlined,
              title: 'Offline Mode',
              subtitle: 'Use on-device model without internet',
              trailing: Switch(
                value: false,
                activeColor: AppTheme.primary,
                onChanged: (v) => _snack('Offline model will be available after training completes'),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _section(context, 'Voice & Haptics', [
            _tile(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              subtitle: 'Vibrate on send',
              trailing: Switch(
                value: _hapticOn,
                activeColor: AppTheme.primary,
                onChanged: (v) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('haptic_feedback', v);
                  setState(() => _hapticOn = v);
                },
              ),
            ),
            _tile(
              icon: Icons.volume_up_outlined,
              title: 'Text-to-Speech',
              subtitle: 'Coming after model deployment',
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _snack('TTS coming after model deployment'),
            ),
            _tile(
              icon: Icons.mic_outlined,
              title: 'Voice Input',
              subtitle: 'Coming in next update',
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _snack('Voice input coming in next update'),
            ),
          ]),

          const SizedBox(height: 24),

          _section(context, 'Appearance', [
            _buildThemeSelector(context),
          ]),

          const SizedBox(height: 24),

          _section(context, 'Connect', [
            _tile(
              icon: Icons.code,
              title: 'GitHub',
              subtitle: '@paumkim/zomi-website',
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _copy('https://github.com/paumkim'),
            ),
            _tile(
              icon: Icons.cloud_outlined,
              title: 'Hugging Face',
              subtitle: 'paumkim/zomi-qlora-v1',
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _copy('https://huggingface.co/paumkim'),
            ),
            _tile(
              icon: Icons.feedback_outlined,
              iconColor: AppTheme.primary,
              title: 'Send Feedback',
              subtitle: 'Report bugs or suggest improvements',
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _showFeedbackDialog(context),
            ),
          ]),

          const SizedBox(height: 24),

          _section(context, 'Training', [
            _buildTrainingProgress(context),
            _tile(
              icon: Icons.storage,
              title: 'Cached Translations',
              subtitle: '${_cacheCount} words saved for offline use',
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _snack('Translations cached: $_cacheCount'),
            ),
          ]),

          const SizedBox(height: 24),

          _section(context, 'Dev Notes', [
            _buildDevNote(context),
          ]),

          const SizedBox(height: 24),

          _section(context, 'About', [
            const _InfoTile(label: 'Version', value: AppConfig.version),
            const _InfoTile(label: 'Model', value: 'Qwen 2.5 3B'),
            const _InfoTile(label: 'Dataset', value: 'Zomi Corpus 3M+'),
            const _InfoTile(label: 'Built with', value: 'Flutter · PyTorch · HF'),
            _tile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
          ]),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made for the Zomi people',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            )),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    String? title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textSecondaryLight),
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.w500))
          : null,
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 13))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('Link copied to clipboard');
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'Your feedback helps improve Pau for everyone.\n\n'
          'Write to us at:\npau.app@zomi.dev\n\n'
          'Or open an issue on GitHub.'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'pau.app@zomi.dev'));
              Navigator.pop(ctx);
              _snack('Email address copied');
            },
            child: const Text('Copy Email'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text: 'https://github.com/paumkim/zomi-website/issues'));
              Navigator.pop(ctx);
              _snack('GitHub issues link copied');
            },
            child: const Text('GitHub Issues'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingProgress(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.model_training, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Phase 1 — Pre-training',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                  color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.625,
              minHeight: 8,
              backgroundColor: AppTheme.primary.withAlpha(20),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step 5,002 / 8,005',
                style: TextStyle(fontSize: 11,
                  color: AppTheme.textSecondaryLight)),
              Text('62.5%',
                style: TextStyle(fontSize: 11,
                  color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Qwen 2.5 3B · QLoRA rank 128 · ~14h remaining',
            style: TextStyle(fontSize: 11,
              color: AppTheme.textSecondaryLight)),
          const SizedBox(height: 4),
          Text('Phase 2 (instruction fine-tuning) queued after Phase 1',
            style: TextStyle(fontSize: 11,
              color: AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildDevNote(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2A1A) : const Color(0xFFFFF8E1);
    final borderColor = isDark
        ? const Color(0xFF3A3A2A)
        : const Color(0xFFF0E68C).withAlpha(100);
    final textColor = isDark ? const Color(0xFFD4C68A) : const Color(0xFF5C4A1E);
    final headerColor = isDark ? const Color(0xFFBBA55A) : const Color(0xFF8B6914);
    final arrowColor = isDark ? const Color(0xFF8A7A3A) : const Color(0xFF8B6914);

    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, size: 16, color: headerColor),
              const SizedBox(width: 8),
              Text('What\'s cooking',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                  color: headerColor)),
            ],
          ),
          const SizedBox(height: 10),
          _noteItem('Voice input — speak in Zomi, get translations',
            arrowColor, textColor),
          _noteItem('Text-to-speech — hear translations aloud',
            arrowColor, textColor),
          _noteItem('Offline model — use Pau without internet',
            arrowColor, textColor),
          _noteItem('iOS version — bring Pau to Apple users',
            arrowColor, textColor),
          const SizedBox(height: 6),
          Text('Training: Phase 1 at 62.5% (Qwen 2.5 3B QLoRA)',
            style: TextStyle(fontSize: 11, color: headerColor.withAlpha(150))),
          Text('Last updated: June 14, 2026',
            style: TextStyle(fontSize: 11, color: headerColor.withAlpha(150))),
        ],
      ),
    );
  }

  Widget _noteItem(String text, Color arrowColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('→ ', style: TextStyle(fontSize: 13, color: arrowColor)),
          Expanded(
            child: Text(text,
              style: TextStyle(fontSize: 13, color: textColor, height: 1.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final options = ['system', 'light', 'dark'];
    final labels = ['Automatic', 'Light', 'Dark'];
    final icons = [Icons.brightness_auto, Icons.light_mode, Icons.dark_mode];
    final current = themeNotifier.value == ThemeMode.light ? 'light'
        : themeNotifier.value == ThemeMode.dark ? 'dark' : 'system';

    return Column(
      children: List.generate(options.length, (i) {
        final selected = current == options[i];
        return RadioListTile<String>(
          title: Row(
            children: [
              Icon(icons[i], size: 18,
                color: selected ? AppTheme.primary : null),
              const SizedBox(width: 8),
              Text(labels[i]),
            ],
          ),
          value: options[i],
          groupValue: current,
          activeColor: AppTheme.primary,
          onChanged: (v) async {
            if (v == null) return;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('app_theme', v);
            themeNotifier.value = v == 'light'
                ? ThemeMode.light
                : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
          },
        );
      }),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14)),
          Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
