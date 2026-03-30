import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_app/screens/prediction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMMM yyyy', 'id');
  final DateFormat _dayFormat = DateFormat('d', 'id');
  final DateFormat _monthFormat = DateFormat('MMMM', 'id');
  
  // Data dummy untuk kalender
  final Map<DateTime, Map<String, dynamic>> _cycleData = {
    DateTime(2026, 3, 1): {'type': 'menstruation', 'intensity': 'heavy'},
    DateTime(2026, 3, 2): {'type': 'menstruation', 'intensity': 'heavy'},
    DateTime(2026, 3, 3): {'type': 'menstruation', 'intensity': 'medium'},
    DateTime(2026, 3, 4): {'type': 'menstruation', 'intensity': 'light'},
    DateTime(2026, 3, 5): {'type': 'menstruation', 'intensity': 'light'},
    DateTime(2026, 3, 15): {'type': 'ovulation', 'fertility': 'high'},
    DateTime(2026, 4, 3): {'type': 'prediction', 'confidence': 'high'},
    DateTime(2026, 4, 4): {'type': 'prediction', 'confidence': 'high'},
    DateTime(2026, 4, 5): {'type': 'prediction', 'confidence': 'medium'},
  };

  // Data ringkasan
  final Map<String, dynamic> _summaryData = {
    'avgCycleLength': 31,
    'lastPeriod': '1 - 5 Maret 2026',
    'nextPeriod': '3 April 2026',
    'ovulationDate': '15 Maret 2026',
    'fertilityWindow': '13-17 Maret 2026',
    'daysUntilNext': 18,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Siklus Haidku'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifikasi
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showProfileMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan info siklus
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cycle info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCycleInfo(
                        icon: Icons.calendar_month,
                        value: '${_summaryData['avgCycleLength']}',
                        label: 'Hari',
                        sublabel: 'Rata-rata siklus',
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildCycleInfo(
                        icon: Icons.favorite,
                        value: '${_summaryData['daysUntilNext']}',
                        label: 'Hari lagi',
                        sublabel: 'Menjelang haid',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Next period prediction
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prediksi Haid',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _summaryData['nextPeriod'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.egg,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ovulasi: 15 Mar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Calendar Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month - 1,
                            );
                          });
                        },
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
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Day headers
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('R', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('K', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('J', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  // Calendar grid
                  Expanded(
                    child: _buildCalendarGrid(),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Legend
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _LegendItem(color: Colors.red, label: 'Haid'),
                      _LegendItem(color: Colors.pink, label: 'Prediksi'),
                      _LegendItem(color: Colors.purple, label: 'Ovulasi'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Quick actions
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_circle,
                    label: 'Catat Haid',
                    color: Colors.red,
                    onTap: () {
                      // TODO: Catat haid
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.auto_graph,
                    label: 'Prediksi',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PredictionScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int firstWeekday = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday;
    
    // Adjust for Sunday as first day (1 = Monday in Dart, we want 1 = Sunday)
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    
    List<Widget> dayWidgets = [];
    
    // Empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(_selectedDate.year, _selectedDate.month, day);
      bool isToday = currentDate.day == DateTime.now().day &&
                     currentDate.month == DateTime.now().month &&
                     currentDate.year == DateTime.now().year;
      
      dayWidgets.add(
        _buildCalendarDay(day, currentDate, isToday),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1,
      children: dayWidgets,
    );
  }

  Widget _buildCalendarDay(int day, DateTime date, bool isToday) {
    final dayData = _cycleData[DateTime(date.year, date.month, date.day)];
    Color? backgroundColor;
    
    if (dayData != null) {
      switch(dayData['type']) {
        case 'menstruation':
          backgroundColor = Colors.red.withOpacity(0.2);
          break;
        case 'prediction':
          backgroundColor = Colors.pink.withOpacity(0.2);
          break;
        case 'ovulation':
          backgroundColor = Colors.purple.withOpacity(0.2);
          break;
      }
    }
    
    return GestureDetector(
      onTap: () {
        _showDayDetails(date, dayData);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: Colors.pink, width: 2) : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Colors.pink : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleInfo({
    required IconData icon,
    required String value,
    required String label,
    required String sublabel,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.pink),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(DateTime date, Map<String, dynamic>? data) {
    String title = DateFormat('EEEE, d MMMM yyyy', 'id').format(date);
    String content;
    
    if (data == null) {
      content = 'Tidak ada catatan untuk hari ini';
    } else {
      switch(data['type']) {
        case 'menstruation':
          content = 'Hari haid (${data['intensity'] == 'heavy' ? 'Deras' : data['intensity'] == 'medium' ? 'Sedang' : 'Ringan'})';
          break;
        case 'prediction':
          content = 'Prediksi haid (akurasi: ${data['confidence']})';
          break;
        case 'ovulation':
          content = 'Masa ovulasi (kesuburan ${data['fertility']})';
          break;
        default:
          content = 'Tidak ada catatan khusus';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Tambah/edit catatan
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.pink,
            ),
            child: const Text('Tambah Catatan'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bunga',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'bunga@example.com',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.pink),
              title: const Text('Edit Profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Edit profil
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.pink),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pengaturan
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah kamu yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Logout
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}