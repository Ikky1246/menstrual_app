// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'daily_note_screen.dart';
import 'mirai_chat_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  // Data Dashboard
  DateTime _selectedDate = DateTime(2026, 5);
  final DateFormat _dateFormat = DateFormat('MMMM yyyy', 'id');

  final Map<DateTime, Map<String, dynamic>> _cycleData = {
    DateTime(2026, 5, 1): {'type': 'prediction', 'intensity': 'light'},
    DateTime(2026, 5, 2): {'type': 'menstruation', 'intensity': 'heavy'},
    DateTime(2026, 5, 3): {'type': 'menstruation', 'intensity': 'heavy'},
    DateTime(2026, 5, 13): {'type': 'ovulation'},
    DateTime(2026, 5, 14): {'type': 'ovulation'},
  };

  final Map<String, dynamic> _summaryData = {
    'cycleLength': 28,
    'daysUntilNext': 27,
    'currentDay': 1,
    'nextPeriod': '09 June 2026',
  };

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildDashboardContent(),
      const DailyNoteScreen(),
      const MiraiChatScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'MIRAI',
          style: TextStyle(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.pink),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
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

  // ==================== KONTEN DASHBOARD ====================
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'PANJANG SIKLUS',
                  value: '${_summaryData['cycleLength']}',
                  unit: 'hari',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'HAID BERIKUTNYA',
                  value: '${_summaryData['daysUntilNext']}',
                  unit: 'hari lagi',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Big Circle
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.pink.withOpacity(0.3),
                width: 12,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hari ke-1',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                Text(
                  'siklus',
                  style: TextStyle(fontSize: 16, color: Colors.pink),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Prediction
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Text(
                  'Prediksi:',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Text(
                  _summaryData['nextPeriod'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop, color: Colors.pink, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Peluang Ovulasi Rendah',
                        style: TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Calendar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {},
                    ),
                    Text(
                      _dateFormat.format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Sen', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Sel', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Rab', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Kam', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Jum', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Sab', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Min', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCalendarGrid(),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(color: Colors.red, label: 'Haid'),
              SizedBox(width: 24),
              _LegendItem(color: Colors.purple, label: 'Ovulasi'),
            ],
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyNoteScreen()),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: const Text(
                'Catatan Harian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final days = List.generate(31, (index) => index + 1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final date = DateTime(2026, 5, day);
        final data = _cycleData[date];

        Color? bgColor;
        Color textColor = Colors.black87;

        if (data != null) {
          if (data['type'] == 'menstruation') {
            bgColor = Colors.red;
            textColor = Colors.white;
          } else if (data['type'] == 'ovulation') {
            bgColor = Colors.purple;
            textColor = Colors.white;
          } else if (data['type'] == 'prediction') {
            bgColor = Colors.pink.shade100;
          }
        }

        return Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
