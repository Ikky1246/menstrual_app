// lib/screens/mirai_chat_screen.dart
// REDESIGNED UI - Mengikuti desain MIRAI Chat dari HTML
// Logika tetap sama, hanya tampilan yang diubah

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/gemini_service.dart';
import '../services/auth_service.dart'; // <-- TAMBAHKAN
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

  final Color primary = const Color(0xFFEC1E63);
  final Color primaryLight = const Color(0xFFFFD3E0);
  final Color surface = const Color(0xFFFFF8F7);
  final Color onSurface = const Color(0xFF281719);
  final Color onSurfaceVariant = const Color(0xFF5C3F43);

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  
  // Hapus konstanta statis, gunakan dynamic key

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  // ==============================================
  // KEY UNIK PER USER
  // ==============================================
  Future<String> _getChatHistoryKey() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?.idUser ?? 'guest';
    return 'mirai_chat_history_$userId';
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMsg = ChatMessage(
        text:
            "Halo! Aku Mirai, asisten kesehatan wanita. Ada yang bisa aku bantu hari ini? 😊",
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
    final key = await _getChatHistoryKey();
    final String? historyJson = prefs.getString(key);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages = decoded
              .map((item) => ChatMessage.fromJson(item))
              .toList();
        });
        _scrollToBottom();
      } catch (e) {
        debugPrint("Error loading chat history: $e");
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getChatHistoryKey();
    final List<Map<String, dynamic>> messagesJson = 
        _messages.map((msg) => msg.toJson()).toList();
    await prefs.setString(key, jsonEncode(messagesJson));
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
      // Siapkan history untuk Gemini
      List<Map<String, String>> history = [];
      final startIndex = _messages.length > 11 ? _messages.length - 11 : 0;
      for (int i = startIndex; i < _messages.length - 1; i++) {
        final msg = _messages[i];
        history.add({
          'role': msg.isUser ? 'user' : 'model',
          'content': msg.text,
        });
      }
      
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
        _messages.add(
          ChatMessage(
            text: "Maaf, terjadi kesalahan. Silakan coba lagi nanti.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Riwayat Chat',
          style: TextStyle(color: Color(0xFFEC1E63)),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus semua riwayat chat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF5C3F43)),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Hapus riwayat untuk user ini
              final prefs = await SharedPreferences.getInstance();
              final key = await _getChatHistoryKey();
              await prefs.remove(key);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
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

  // ==================== BUILD UI (SAMA SEPERTI SEBELUMNYA) ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7),
      body: Column(
        children: [
          // ===== GLASS TOP APP BAR =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.6)),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.arrow_back,
                      color: onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
                const Spacer(),
                // Title
                const Text(
                  "MIRAI",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
                    color: Color(0xFFEC1E63),
                  ),
                ),
                const Spacer(),
                // Delete Button
                GestureDetector(
                  onTap: _clearChatHistory,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.delete_outline,
                      color: onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== CHAT AREA =====
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryLight.withOpacity(0.3),
                    surface.withOpacity(0.5),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Animated Background Decorations
                  ..._buildBackgroundDecorations(),

                  // Chat Messages
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 180),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      if (!message.isUser) {
                        return _buildBotMessage(
                          message.text,
                          _formatTime(message.timestamp),
                        );
                      } else {
                        return _buildUserMessage(
                          message.text,
                          _formatTime(message.timestamp),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ===== GLASS INPUT AREA =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  primaryLight.withOpacity(0.8),
                  primaryLight.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ketik pesanmu di sini...",
                        hintStyle: TextStyle(
                          color: onSurfaceVariant.withOpacity(0.6),
                          fontFamily: 'PlusJakartaSans',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'PlusJakartaSans',
                        color: Color(0xFF281719),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEC1E63), Color(0xFFFFD3E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
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
  }

  List<Widget> _buildBackgroundDecorations() {
    return [
      // Sakura Petals
      Positioned(
        top: 80,
        left: 40,
        child: _buildSakuraPetal(size: 32, opacity: 0.2, animationDelay: 0),
      ),
      Positioned(
        top: 240,
        right: 40,
        child: _buildSakuraPetal(size: 24, opacity: 0.3, animationDelay: 2),
      ),
      Positioned(
        bottom: 160,
        left: 80,
        child: _buildSakuraPetal(size: 40, opacity: 0.15, animationDelay: 1),
      ),
      // Blur Circles
      Positioned(
        top: 40,
        left: 40,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(200),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.05),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 16,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(220),
            boxShadow: [
              BoxShadow(
                color: primaryLight.withOpacity(0.1),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        bottom: 100,
        left: 80,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(200),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.03),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildSakuraPetal({
    required double size,
    required double opacity,
    required int animationDelay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(seconds: 6),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final yOffset =
            (value *
            20 *
            (animationDelay == 0
                ? 1
                : animationDelay == 2
                ? 1.3
                : 1.6));
        final rotation = value * 0.2;
        return Transform.translate(
          offset: Offset(
            0,
            -yOffset * (value < 0.5 ? value * 2 : (1 - value) * 2),
          ),
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity:
                  opacity *
                  (0.8 + 0.2 * (value < 0.5 ? value * 2 : (1 - value) * 2)),
              child: Icon(Icons.favorite, color: primary, size: size),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotMessage(String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC1E63), Color(0xFFFFD3E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face_4,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "MIRAI Guide",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceVariant,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(topLeft: Radius.zero),
                border: Border.all(color: primary.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontFamily: 'PlusJakartaSans',
                  color: Color(0xFF281719),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 4),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: onSurfaceVariant.withOpacity(0.6),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEC1E63),
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(topRight: Radius.zero),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC1E63).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  fontFamily: 'PlusJakartaSans',
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: onSurfaceVariant.withOpacity(0.6),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: primary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC1E63), Color(0xFFFFD3E0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.face_4,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "MIRAI Guide",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceVariant,
                    fontFamily: 'PlusJakartaSans',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  16,
                ).copyWith(topLeft: Radius.zero),
                border: Border.all(color: primary.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "MIRAI sedang mengetik...",
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant.withOpacity(0.7),
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
