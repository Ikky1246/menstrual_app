import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_app/screens/prediction_screen.dart';
import 'package:menstrual_app/screens/auth/login_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/models/user_model.dart';
import 'package:menstrual_app/utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMMM yyyy', 'id');
  
  User? _currentUser;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  
  // Data siklus dari API
  Map<String, dynamic> _cycleData = {};
  Map<String, dynamic> _summaryData = {
    'avgCycleLength': 28,
    'lastPeriod': '-',
    'nextPeriod': '-',
    'ovulationDate': '-',
    'fertilityWindowStart': '-',
    'fertilityWindowEnd': '-',
    'daysUntilNext': 0,
  };
  
  // Data untuk kalender
  List<DateTime> _menstruationDates = [];
  List<DateTime> _predictionDates = [];
  List<DateTime> _ovulationDates = [];
  DateTime? _nextPeriodDate;
  int _cycleLength = 28;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCycleData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _loadCycleData() async {
    try {
      final result = await CycleService.getLatestCycle();
      if (result['success'] == true && result['cycle'] != null) {
        final cycle = result['cycle'];
        
        // Ambil data dari cycle
        _cycleLength = cycle.cycleLengthDays ?? 28;
        final lastPeriodDate = cycle.lastPeriodDate != null 
            ? DateTime.parse(cycle.lastPeriodDate) 
            : null;
        
        // Hitung tanggal haid berikutnya
        if (lastPeriodDate != null) {
          _nextPeriodDate = lastPeriodDate.add(Duration(days: _cycleLength));
          
          // Hitung tanggal ovulasi (14 hari sebelum haid berikutnya)
          final ovulationDate = _nextPeriodDate!.subtract(const Duration(days: 14));
          
          // Format tanggal
          String lastPeriodFormatted = lastPeriodDate != null
              ? DateFormat('dd MMMM yyyy', 'id').format(lastPeriodDate)
              : '-';
          
          String nextPeriodFormatted = _nextPeriodDate != null
              ? DateFormat('dd MMMM yyyy', 'id').format(_nextPeriodDate!)
              : '-';
          
          String ovulationFormatted = ovulationDate != null
              ? DateFormat('dd MMMM yyyy', 'id').format(ovulationDate)
              : '-';
          
          // Hitung hari sampai haid berikutnya
          int daysUntilNext = _nextPeriodDate != null
              ? _nextPeriodDate!.difference(DateTime.now()).inDays
              : 0;
          
          // Window subur: 5 hari sebelum ovulasi sampai ovulasi
          final fertileStart = ovulationDate.subtract(const Duration(days: 5));
          final fertileEnd = ovulationDate;
          
          setState(() {
            _summaryData = {
              'avgCycleLength': _cycleLength,
              'lastPeriod': lastPeriodFormatted,
              'nextPeriod': nextPeriodFormatted,
              'ovulationDate': ovulationFormatted,
              'fertilityWindowStart': DateFormat('dd MMM', 'id').format(fertileStart),
              'fertilityWindowEnd': DateFormat('dd MMM', 'id').format(fertileEnd),
              'daysUntilNext': daysUntilNext > 0 ? daysUntilNext : 0,
            };
          });
          
          // Generate dates untuk kalender
          _generateCalendarDates(lastPeriodDate, _nextPeriodDate!, ovulationDate);
        }
      }
    } catch (e) {
      print('Error loading cycle data: $e');
    }
  }
  
  // ==============================================
  // GENERATE DATES UNTUK KALENDER
  // ==============================================
  void _generateCalendarDates(DateTime lastPeriod, DateTime nextPeriod, DateTime ovulation) {
    setState(() {
      // 1. HARI HAID (5 hari setelah lastPeriod)
      _menstruationDates = [];
      for (int i = 0; i < 5; i++) {
        _menstruationDates.add(lastPeriod.add(Duration(days: i)));
      }
      
      // 2. HARI PREDIKSI (periode yang diprediksi)
      _predictionDates = [];
      for (int i = 0; i < 5; i++) {
        _predictionDates.add(nextPeriod.add(Duration(days: i)));
      }
      
      // 3. HARI OVULASI
      _ovulationDates = [ovulation];
    });
  }

  // ==============================================
  // LOGOUT FUNCTION
  // ==============================================
  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    final result = await AuthService.logout();

    setState(() {
      _isLoggingOut = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil keluar 👋'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal keluar'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Keluar'),
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
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.pink,
              child: Text(
                _currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentUser?.namaLengkap ?? _currentUser?.name ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              _currentUser?.email ?? '-',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.pink),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.pink),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur dalam pengembangan')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar', style: TextStyle(color: Colors.red)),
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

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Saya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Nama', _currentUser?.namaLengkap ?? _currentUser?.name ?? '-'),
            const Divider(),
            _buildProfileRow('Email', _currentUser?.email ?? '-'),
            const Divider(),
            _buildProfileRow('No. Telepon', _currentUser?.noTelepon ?? '-'),
            const Divider(),
            _buildProfileRow('Usia', _currentUser?.age != null ? '${_currentUser!.age} tahun' : '-'),
            const Divider(),
            _buildProfileRow('Status', _currentUser?.status ?? '-'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // ==============================================
  // BUILD KALENDER
  // ==============================================
  
  Widget _buildCalendarGrid() {
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int firstWeekday = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday;
    
    // Konversi ke index Minggu (Minggu = 0)
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;
    
    List<Widget> dayWidgets = [];
    
    // Empty cells untuk hari sebelum tanggal 1
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    // Loop setiap tanggal dalam bulan
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime currentDate = DateTime(_selectedDate.year, _selectedDate.month, day);
      bool isToday = currentDate.day == DateTime.now().day &&
                     currentDate.month == DateTime.now().month &&
                     currentDate.year == DateTime.now().year;
      
      dayWidgets.add(_buildCalendarDay(day, currentDate, isToday));
    }
    
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 1,
      children: dayWidgets,
    );
  }

  Widget _buildCalendarDay(int day, DateTime date, bool isToday) {
    // Cek status tanggal
    bool isMenstruation = _isDateInList(date, _menstruationDates);
    bool isPrediction = _isDateInList(date, _predictionDates);
    bool isOvulation = _isDateInList(date, _ovulationDates);
    
    // Tentukan warna background
    Color? backgroundColor;
    Color textColor = Colors.black;
    
    if (isMenstruation) {
      backgroundColor = Colors.pink.shade100;  // Pink muda untuk haid
      textColor = Colors.pink.shade800;
    } else if (isPrediction) {
      backgroundColor = Colors.pink.shade50;   // Pink sangat muda untuk prediksi
      textColor = Colors.pink.shade600;
    } else if (isOvulation) {
      backgroundColor = Colors.purple.shade100; // Ungu muda untuk ovulasi
      textColor = Colors.purple.shade800;
    }
    
    // Border untuk prediksi (lingkaran putus-putus)
    Border? border;
    if (isPrediction && !isMenstruation) {
      border = Border.all(
        color: Colors.pink.shade400,
        width: 1.5,
        style: BorderStyle.solid,
      );
    }
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: border,
        boxShadow: isToday ? [
          BoxShadow(
            color: Colors.pink.shade200,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lingkaran untuk hari ini (opsional)
          if (isToday && !isMenstruation && !isPrediction)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink, width: 2),
              ),
            ),
          
          // Nomor tanggal
          Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ),
          
          // Dot kecil untuk ovulasi
          if (isOvulation)
            Positioned(
              bottom: 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  bool _isDateInList(DateTime date, List<DateTime> dateList) {
    return dateList.any((d) => 
        d.year == date.year && 
        d.month == date.month && 
        d.day == date.day);
  }

  // ==============================================
  // BUILD WIDGET CYCLE INFO
  // ==============================================
  
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          sublabel,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================
  // MAIN BUILD
  // ==============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Siklusku'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur dalam pengembangan')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showProfileMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : Column(
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
                        color: Colors.pink.withValues(alpha: 0.3),
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
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _summaryData['nextPeriod'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.egg, color: Colors.white, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  'Ovulasi: ${_summaryData['ovulationDate']}',
                                  style: const TextStyle(color: Colors.white),
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
                          color: Colors.grey.withValues(alpha: 0.1),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        
                        // Day headers (S S R K J S M)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegendItem(color: Colors.pink.shade100, label: 'Haid', isCircle: false),
                            _buildLegendItem(color: Colors.pink.shade50, label: 'Prediksi', isCircle: true),
                            _buildLegendItem(color: Colors.purple.shade100, label: 'Ovulasi', isCircle: false),
                            _buildLegendItem(color: Colors.transparent, label: 'Hari ini', isCircle: true, hasBorder: true),
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
                            // TODO: Buka halaman record cycle
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur dalam pengembangan')),
                            );
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
  
  Widget _buildLegendItem({
    required Color color,
    required String label,
    required bool isCircle,
    bool hasBorder = false,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.pink, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}