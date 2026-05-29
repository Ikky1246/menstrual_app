// lib/screens/mirai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';

class MiraiChatScreen extends StatefulWidget {
  const MiraiChatScreen({super.key});

  @override
  State<MiraiChatScreen> createState() => _MiraiChatScreenState();
}

class _MiraiChatScreenState extends State<MiraiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  final Color primary = const Color(0xFF9B0044);
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  
  static const String _chatHistoryKey = 'mirai_chat_history';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMsg = ChatMessage(
        text: "Halo! Aku Mirai, asisten kesehatan wanita. Ada yang bisa aku bantu hari ini? 😊",
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(welcomeMsg);
      });
      _saveChatHistory();
    }
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_chatHistoryKey);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages = decoded.map((item) => ChatMessage.fromJson(item)).toList();
        });
        _scrollToBottom();
      } catch (e) {
        debugPrint("Error loading chat history: $e");
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> messagesJson = 
        _messages.map((msg) => msg.toJson()).toList();
    await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Tambahkan pesan user ke UI
    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });
    _controller.clear();
    _saveChatHistory();
    _scrollToBottom();

    try {
      // Siapkan history untuk Gemini (konversi dari _messages ke format yang diinginkan)
      List<Map<String, String>> history = [];
      // Ambil maksimal 10 pesan terakhir (hindari token terlalu panjang)
      final startIndex = _messages.length > 11 ? _messages.length - 11 : 0;
      for (int i = startIndex; i < _messages.length - 1; i++) {
        final msg = _messages[i];
        history.add({
          'role': msg.isUser ? 'user' : 'model',
          'content': msg.text,
        });
      }
      
      // Kirim ke Gemini dengan history
      final response = await _geminiService.sendMessageWithHistory(text, history);
      
      final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _isLoading = false;
        _isTyping = false;
        _messages.add(botMessage);
      });
      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending message: $e");
      setState(() {
        _isLoading = false;
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "Maaf, terjadi kesalahan. Silakan coba lagi nanti.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat Chat'),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              _saveChatHistory();
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "MIRAI",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xFF9B0044),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF9B0044)),
            onPressed: _clearChatHistory,
            tooltip: 'Hapus riwayat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                if (!message.isUser) {
                  return _buildBotMessage(message.text, _formatTime(message.timestamp));
                } else {
                  return _buildUserMessage(message.text, _formatTime(message.timestamp));
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ketik pesanmu di sini...",
                      filled: true,
                      fillColor: const Color(0xFFF2F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: primary,
                  elevation: 2,
                  mini: true,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(String text, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primary,
                child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                "MIRAI Guide",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF685B60),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0DEE4),
              borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(16).copyWith(topRight: Radius.zero),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.done_all, size: 14, color: Color(0xFF9B0044)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: primary,
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0DEE4),
                borderRadius: BorderRadius.circular(16).copyWith(topLeft: Radius.zero),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9B0044)),
                  ),
                  SizedBox(width: 8),
                  Text("MIRAI sedang mengetik...", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}