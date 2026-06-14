import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                Text('Privacy Policy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Last updated: June 14, 2026',
                    style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13)),
                  const SizedBox(height: 24),
                  _section(context, 'What Pau does',
                      'Pau is a translation and language assistant app for Zomi speakers. It translates text between Zomi, English, Malay, and Chinese.'),
                  _section(context, 'Data we collect',
                      'Pau does not collect any personal data.\n\n'
                      '• Translation text is sent to our model server to generate translations. We do not log, store, or share your translations.\n'
                      '• No account is required. No tracking. No analytics. No ads.\n'
                      '• The app works entirely on-device when the offline model is downloaded.'),
                  _section(context, 'Data storage',
                      '• Translation history is stored only on your device in local storage. You can clear it anytime.\n'
                      '• If you download the offline model, it stays on your device. You can delete it anytime.'),
                  _section(context, 'Permissions',
                      '• Internet — to send translation requests and download the offline model.\n'
                      '• Microphone — only if you use voice input. Audio is never stored or shared.'),
                  _section(context, 'Third-party services',
                      '• Hugging Face Inference API — used for cloud translation. Their privacy policy applies to data sent through their API.\n'
                      '• GitHub — we link to our open-source repository. No data is sent to GitHub by the app.'),
                  _section(context, 'Contact',
                      'pau.app@zomi.dev\n'
                      'github.com/paumkim/zomi-website/issues'),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(body,
            style: TextStyle(
              height: 1.5, color: AppTheme.textSecondaryLight, fontSize: 14)),
        ],
      ),
    );
  }
}
