import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../services/hive_storage.dart';
import '../services/connectivity_service.dart';
import '../config/globals.dart';
import '../widgets/error_widgets.dart';
import '../widgets/keyboard_dismiss.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> with WidgetsBindingObserver {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hapticOn = true;
  String? _lastError;

  static const _historyFile = 'pau_chat_history';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadHistory();
    _chatService.loadModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatService.cancelRequest();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _hapticOn = prefs.getBool('haptic_feedback') ?? true);
  }

  Future<void> _saveHistory() async {
    try {
      if (HiveStorage.isAvailable) {
        await HiveStorage.clearChatHistory();
        for (var m in _messages) {
          await HiveStorage.saveChatMessage({
            'text': m.text, 'isUser': m.isUser, 'time': m.time.toIso8601String()
          });
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final data = _messages.map((m) => {
          'text': m.text, 'isUser': m.isUser, 'time': m.time.toIso8601String()
        }).toList();
        await prefs.setString(_historyFile, jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Failed to save chat history: $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      List<Map<String, dynamic>> items;
      if (HiveStorage.isAvailable) {
        items = await HiveStorage.getChatHistory();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_historyFile);
        if (raw == null || raw.isEmpty) return;
        items = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      }
      final loaded = items.map((e) => _ChatMessage(
        text: e['text'] ?? '', isUser: e['isUser'] ?? true,
        time: DateTime.tryParse(e['time'] ?? '') ?? DateTime.now(),
      )).toList();
      // Reverse because Hive returns newest-first
      if (loaded.isNotEmpty && HiveStorage.isAvailable) {
        loaded.sort((a, b) => a.time.compareTo(b.time));
      }
      if (mounted) setState(() => _messages.addAll(loaded));
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

  void _addMessage(_ChatMessage msg) {
    setState(() {
      _messages.add(msg);
      _lastError = null;
    });
    _saveHistory();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isLoading) return;
    if (!_chatService.isModelAvailable) {
      setState(() => _lastError = 'Selected model not yet available. Change in Settings.');
      return;
    }

    if (_hapticOn) HapticFeedback.mediumImpact();
    _msgController.clear();

    setState(() => _isLoading = true);
    _addMessage(_ChatMessage(text: text, isUser: true));

    // Create a placeholder bot message that gets filled via streaming
    final botMsg = _ChatMessage(text: '', isUser: false);
    setState(() => _messages.add(botMsg));

    String? errorText;
    try {
      await for (final token in _chatService.chatStream(text)) {
        if (mounted) {
          final currentText = _messages.last.text;
          _messages.last = _ChatMessage(
            text: currentText + token, isUser: false, time: _messages.last.time);
          setState(() {});
          _scrollToBottom();
        }
      }
    } catch (e) {
      errorText = 'Stream error: $e';
    }

    if (mounted) {
      // If we got no content, show error
      if (_messages.last.text.isEmpty) {
        _messages.removeLast();
        errorText = errorText ?? 'No response from model.';
      }
      setState(() {
        _isLoading = false;
        if (errorText != null) _lastError = errorText;
      });
      _saveHistory();
    }
  }

  void _cancelStreaming() {
    _chatService.cancelRequest();
    if (mounted) {
      setState(() => _isLoading = false);
      // Remove the empty bot message
      if (_messages.isNotEmpty && _messages.last.text.isEmpty && !_messages.last.isUser) {
        setState(() => _messages.removeLast());
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userColor = isDark ? AppTheme.bubbleUserDark : AppTheme.bubbleUserLight;
    final botColor = isDark ? AppTheme.bubbleBotDark : AppTheme.bubbleBotLight;
    final isOffline = connectivityService.isOffline;

    return Scaffold(
      body: KeyboardDismiss(child: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text('Offline — chat unavailable',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                ],
              ),
            ),
          if (_lastError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.error.withAlpha(20),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: AppTheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_lastError!,
                      style: TextStyle(fontSize: 12, color: AppTheme.error))),
                  GestureDetector(
                    onTap: () => setState(() => _lastError = null),
                    child: Icon(Icons.close, size: 16, color: AppTheme.error),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              displacement: 40,
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                HapticFeedback.selectionClick();
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: _messages.isEmpty
                  ? _buildEmpty(context)
                  : _buildMessages(userColor, botColor),
            ),
          ),
          _buildModelIndicator(),
          _buildInput(context, userColor, isDark),
        ],
      ),
      ),
    );
  }

  Widget _buildModelIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.smart_toy_outlined, size: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(60)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(_chatService.currentModel,
              style: TextStyle(fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(60)))),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: _chatService.isModelAvailable ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        EmptyStateWidget(
          icon: Icons.chat_bubble_outline,
          title: 'Start talking',
          subtitle: 'Type anything in English or Zomi.\nPau will respond in kind.',
        ),
      ],
    );
  }

  Widget _buildMessages(Color userColor, Color botColor) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_isLoading &&
          (_messages.isEmpty || _messages.last.isUser || _messages.last.text.isNotEmpty) ? 1 : 0),
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildBubble(msg, userColor, botColor);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg, Color userColor, Color botColor) {
    final isStreaming = !msg.isUser && msg.text.isEmpty && _isLoading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () {
              if (msg.text.isEmpty) return;
              Clipboard.setData(ClipboardData(text: msg.text));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: msg.isUser ? userColor : botColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  isStreaming
                      ? _buildTypingAnimation()
                      : Text(msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : null, height: 1.4)),
                  if (msg.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatTime(msg.time),
                          style: TextStyle(fontSize: 11,
                            color: msg.isUser ? Colors.white60 : Colors.grey)),
                        if (msg.isUser) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check, size: 12, color: Colors.white60),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(Colors.grey.shade400), const SizedBox(width: 4),
          _dot(Colors.grey.shade500), const SizedBox(width: 4),
          _dot(Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildInput(BuildContext context, Color userColor, bool isDark) {
    return Container(
      padding: EdgeInsets.only(left: 12, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.shade300.withAlpha(60))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              textInputAction: TextInputAction.send,
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                filled: true,
                fillColor: isDark ? AppTheme.bubbleBotDark : AppTheme.backgroundLight,
              ),
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isLoading ? Colors.red : userColor,
            child: IconButton(
              icon: _isLoading
                  ? const Icon(Icons.stop, color: Colors.white, size: 18)
                  : const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isLoading ? _cancelStreaming : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  _ChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
}
