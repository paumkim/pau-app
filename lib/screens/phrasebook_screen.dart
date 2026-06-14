import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/phrasebook.dart';
import '../services/translation_cache.dart';

class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
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
                Text('Zomi Phrases',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${Phrasebook.categories.length} categories',
                  style: TextStyle(fontSize: 13,
                    color: AppTheme.textSecondaryLight)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: Phrasebook.categories.length,
              itemBuilder: (_, i) {
                final cat = Phrasebook.categories[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary.withAlpha(20),
                      child: Icon(cat.icon, color: AppTheme.primary, size: 18),
                    ),
                    title: Text('${cat.name} (${cat.phrases.length})',
                      style: const TextStyle(fontWeight: FontWeight.w500,
                        fontSize: 14)),
                    children: cat.phrases.map((p) {
                      return ListTile(
                        dense: true,
                        title: Text(p.english, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(p.zomi,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          )),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: p.zomi));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied'),
                                    duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.save_outlined, size: 16),
                              onPressed: () async {
                                await TranslationCache.set(
                                  p.english, 'en', 'zomi', p.zomi);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Saved to vocabulary'),
                                      duration: Duration(seconds: 1)),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
