import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/hive_storage.dart';
import '../widgets/error_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> _translationHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final chats = HiveStorage.isAvailable
          ? await HiveStorage.getChatHistory()
          : await _legacyGetChats();
      final trans = HiveStorage.isAvailable
          ? await HiveStorage.getTranslationHistory()
          : await _legacyGetTranslations();

      if (mounted) {
        setState(() {
          _chatHistory = chats;
          _translationHistory = trans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _legacyGetChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pau_chat_history');
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  Future<List<Map<String, dynamic>>> _legacyGetTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('translation_history');
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) { return []; }
  }

  Future<void> _deleteChat(int index) async {
    setState(() => _chatHistory.removeAt(index));
    if (HiveStorage.isAvailable) {
      await HiveStorage.clearChatHistory();
      for (var msg in _chatHistory) {
        await HiveStorage.saveChatMessage(msg);
      }
    } else {
      await _legacySaveChats();
    }
  }

  Future<void> _legacySaveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pau_chat_history', jsonEncode(_chatHistory));
  }

  Future<void> _clearAll(String type) async {
    if (type == 'chat') {
      setState(() => _chatHistory.clear());
      await HiveStorage.clearChatHistory();
    } else {
      setState(() => _translationHistory.clear());
      await HiveStorage.clearTranslationHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const AppLoadingShimmer()
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Chat (${_chatHistory.length})'),
                    Tab(text: 'Translations (${_translationHistory.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatList(),
                      _buildTranslationList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChatList() {
    if (_chatHistory.isEmpty) {
      return _buildEmpty('No chats yet', Icons.chat_bubble_outline);
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _chatHistory.length,
          itemBuilder: (context, index) {
            final msg = _chatHistory[index];
            final isUser = msg['isUser'] == true;
            final text = msg['text'] as String? ?? '';
            final time = msg['time'] as String?;
            return Dismissible(
              key: ValueKey('chat_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red.withAlpha(40),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              onDismissed: (_) => _deleteChat(index),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isUser
                        ? AppTheme.primary.withAlpha(30)
                        : AppTheme.accent.withAlpha(30),
                    child: Icon(
                      isUser ? Icons.person : Icons.smart_toy_outlined,
                      size: 16,
                      color: isUser ? AppTheme.primary : AppTheme.accent,
                    ),
                  ),
                  title: Text(text,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, height: 1.3)),
                  subtitle: time != null
                      ? Text(_formatTime(time),
                          style: const TextStyle(fontSize: 11))
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied'),
                          duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 8, right: 8,
          child: FloatingActionButton.small(
            heroTag: 'clear_chat',
            backgroundColor: Colors.red.withAlpha(30),
            child: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
            onPressed: () => _clearAll('chat'),
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationList() {
    if (_translationHistory.isEmpty) {
      return _buildEmpty('No translations yet', Icons.translate);
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _translationHistory.length,
          itemBuilder: (context, index) {
            final t = _translationHistory[index];
            final sourceText = t['sourceText'] as String? ?? '';
            final translatedText = t['translatedText'] as String? ?? '';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 3),
              child: ListTile(
                title: Text(sourceText,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
                subtitle: Text(translatedText,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: translatedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied'),
                        duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 8, right: 8,
          child: FloatingActionButton.small(
            heroTag: 'clear_trans',
            backgroundColor: Colors.red.withAlpha(30),
            child: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
            onPressed: () => _clearAll('translation'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48,
            color: AppTheme.textSecondaryLight.withAlpha(80)),
          const SizedBox(height: 12),
          Text(message,
            style: TextStyle(color: AppTheme.textSecondaryLight)),
        ],
      ),
    );
  }

  String _formatTime(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
