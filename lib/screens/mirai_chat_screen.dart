import 'package:flutter/material.dart';

class MiraiChatScreen extends StatefulWidget {
  const MiraiChatScreen({super.key});

  @override
  State<MiraiChatScreen> createState() => _MiraiChatScreenState();
}

class _MiraiChatScreenState extends State<MiraiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color primary = const Color(0xFF9B0044);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        title: const Text(
          "MIRAI",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Color(0xFF9B0044),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF9B0044)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF9B0044),
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Date Divider
                const Center(
                  child: Chip(
                    label: Text("Hari Ini", style: TextStyle(fontSize: 12)),
                    backgroundColor: Color(0xFFE0E3E5),
                  ),
                ),
                const SizedBox(height: 20),

                // Bot Message
                _buildBotMessage(
                  "Halo! Aku di sini untuk mendukung perjalanan kesehatanmu. Bagaimana perasaanmu hari ini?",
                  "09:41",
                ),

                const SizedBox(height: 16),

                // User Message
                _buildUserMessage(
                  "Akhir-akhir ini aku merasa lebih mudah lelah dari biasanya. Apakah itu normal di fase siklus ini?",
                  "09:42",
                ),

                const SizedBox(height: 16),

                // Bot Message with Recommendation Card
                _buildBotMessageWithCard(
                  "Ya, rasa lelah yang meningkat memang cukup umum saat tubuh mempersiapkan fase berikutnya. Aku sarankan kamu mencatat kualitas tidur malam ini.",
                  "09:43",
                ),

                const SizedBox(height: 16),

                // User Message 2
                _buildUserMessage(
                  'Makasih informasinya. Bisa bantu aku catat "Catatan Harian" untuk tingkat kelelahan hari ini?',
                  "09:44",
                ),

                const SizedBox(height: 24),

                // Typing Indicator
                Row(
                  children: [
                    const SizedBox(width: 8),
                    _buildTypingIndicator(),
                    const SizedBox(width: 12),
                    const Text(
                      "MIRAI sedang berpikir...",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat Input
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
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.grey,
                  ),
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
                  onPressed: _sendMessage,
                  backgroundColor: primary,
                  elevation: 2,
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: "Catatan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET CHAT ====================

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
                child: const Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: Colors.white,
                ),
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
              borderRadius: BorderRadius.circular(
                16,
              ).copyWith(topLeft: Radius.zero),
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
              borderRadius: BorderRadius.circular(
                16,
              ).copyWith(topRight: Radius.zero),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.4,
              ),
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

  Widget _buildBotMessageWithCard(String text, String time) {
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
                child: const Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: Colors.white,
                ),
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
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0DEE4),
              borderRadius: BorderRadius.circular(
                16,
              ).copyWith(topLeft: Radius.zero),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE1BEC4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB33363),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.bedtime, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Insight Kesehatan",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9B0044),
                              ),
                            ),
                            Text(
                              "Kelelahan Terkait Siklus",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF9B0044)),
                    ],
                  ),
                ),
              ],
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

  Widget _buildTypingIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    // Tambahkan logika pengiriman pesan di sini nanti
    _controller.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
