import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/screens/prediction_screen.dart';
import 'package:menstrual_app/screens/auth/login_screen.dart';
import 'package:menstrual_app/screens/daily_note_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/services/daily_note_service.dart';
import 'package:menstrual_app/models/user_model.dart';
import 'package:menstrual_app/utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = DateTime.now();
  final DateFormat _monthFormat = DateFormat('MMMM yyyy', 'id');
  final DateFormat _dayFormat = DateFormat('EEEE', 'id');
  
  User? _currentUser;
  bool _isLoading = true;
  
  // Data siklus dari API
  Map<String, dynamic> _summaryData = {
    'avgCycleLength': 28,
    'lastPeriod': '-',
    'nextPeriod': '-',
    'ovulationDate': '-',
    'daysUntilNext': 0,
  };
  
  // Data untuk kalender
  List<DateTime> _menstruationDates = [];
  List<DateTime> _predictionDates = [];
  List<DateTime> _ovulationDates = [];
  Map<DateTime, bool> _hasNoteDates = {}; // Tanggal yang ada catatan
  int _cycleLength = 28;
  int _periodDuration = 5;
  
  // Popup koreksi
  bool _showCorrectionPopup = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCycleData();
    _loadPeriodDuration();
    _checkCorrectionNeeded();
  }

  Future<void> _loadPeriodDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final duration = prefs.getInt('period_duration');
    if (duration != null) {
      setState(() {
        _periodDuration = duration;
      });
    }
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadCycleData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CycleService.getLatestCycle();
      print('📊 Dashboard - Latest cycle result: $result');
      
      if (result['success'] == true && result['cycle'] != null) {
        final cycle = result['cycle'];
        
        _cycleLength = cycle.cycleLengthDays ?? 28;
        DateTime lastPeriodDate = cycle.lastPeriodDate;
        
        // Hitung tanggal haid berikutnya
        final nextPeriodDate = lastPeriodDate.add(Duration(days: _cycleLength));
        
        // Hitung tanggal ovulasi (14 hari sebelum haid berikutnya)
        final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
        
        // Format tanggal
        String lastPeriodFormatted = DateFormat('dd MMMM yyyy', 'id').format(lastPeriodDate);
        String nextPeriodFormatted = DateFormat('dd MMMM yyyy', 'id').format(nextPeriodDate);
        String ovulationFormatted = DateFormat('dd MMMM yyyy', 'id').format(ovulationDate);
        
        // Hitung hari sampai haid berikutnya
        int daysUntilNext = nextPeriodDate.difference(DateTime.now()).inDays;
        if (daysUntilNext < 0) daysUntilNext = 0;
        
        setState(() {
          _summaryData = {
            'avgCycleLength': _cycleLength,
            'lastPeriod': lastPeriodFormatted,
            'nextPeriod': nextPeriodFormatted,
            'ovulationDate': ovulationFormatted,
            'daysUntilNext': daysUntilNext,
          };
        });
        
        // Generate dates untuk kalender
        _generateCalendarDates(lastPeriodDate, nextPeriodDate, ovulationDate);
      }
      
      // Load catatan harian untuk bulan ini
      await _loadNotesForMonth();
      
    } catch (e) {
      print('Error loading cycle data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotesForMonth() async {
    final result = await DailyNoteService.getNotesForMonth(
      _selectedDate.year, 
      _selectedDate.month
    );
    
    if (result['success'] == true && result['notes'] != null) {
      final notesMap = result['notes'] as Map<String, bool>;
      setState(() {
        _hasNoteDates.clear();
        for (var entry in notesMap.entries) {
          final dateParts = entry.key.split('-');
          if (dateParts.length == 3) {
            final date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
            _hasNoteDates[date] = true;
          }
        }
      });
    }
  }

  void _generateCalendarDates(DateTime lastPeriod, DateTime nextPeriod, DateTime ovulation) {
    setState(() {
      // HARI HAID
      _menstruationDates = [];
      for (int i = 0; i < _periodDuration; i++) {
        _menstruationDates.add(lastPeriod.add(Duration(days: i)));
      }
      
      // HARI PREDIKSI HAID BERIKUTNYA
      _predictionDates = [];
      for (int i = 0; i < _periodDuration; i++) {
        _predictionDates.add(nextPeriod.add(Duration(days: i)));
      }
      
      // HARI OVULASI
      _ovulationDates = [ovulation];
    });
  }

  // ============================================
  // CEK APAKAH PERLU KOREKSI SIKLUS
  // ============================================
  Future<void> _checkCorrectionNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCorrectionDate = prefs.getString('last_correction_date');
    final lastPeriodDate = prefs.getString('last_period_date');
    
    if (lastPeriodDate != null) {
      final lastPeriod = DateTime.parse(lastPeriodDate);
      final today = DateTime.now();
      final daysSinceLastPeriod = today.difference(lastPeriod).inDays;
      
      // Jika sudah melewati prediksi haid + 5 hari
      if (daysSinceLastPeriod > _cycleLength + 5) {
        _showCorrectionNeededDialog();
      }
    }
  }

  void _showCorrectionNeededDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Siklus'),
        content: const Text('Apakah Anda sudah mengalami haid?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDatePickerForCorrection();
            },
            child: const Text('Sudah'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Tunda koreksi 3 hari
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kami akan tanyakan lagi dalam 3 hari'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Belum'),
          ),
        ],
      ),
    );
  }

  void _showDatePickerForCorrection() async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 10)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      _saveCorrection(selectedDate);
    }
  }

  Future<void> _saveCorrection(DateTime actualStartDate) async {
    try {
      final result = await CycleService.getLatestCycle();
      if (result['success'] == true && result['cycle'] != null) {
        final cycle = result['cycle'];
        
        // Kirim koreksi ke backend
        final correctionResult = await CycleService.submitCorrection(
          expectedStartDate: cycle.lastPeriodDate.add(Duration(days: _cycleLength)),
          actualStartDate: actualStartDate,
          correctionType: 'start',
        );
        
        if (correctionResult['success'] == true) {
          // Simpan tanggal baru
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_period_date', actualStartDate.toIso8601String());
          await prefs.setString('last_correction_date', DateTime.now().toIso8601String());
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terima kasih! Data siklus telah diperbarui 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Reload data
          await _loadCycleData();
        }
      }
    } catch (e) {
      print('Error saving correction: $e');
    }
  }

  // ============================================
  // BUILD KALENDER GRID
  // ============================================
  
  Widget _buildCalendarGrid() {
    int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    int firstWeekday = DateTime(_selectedDate.year, _selectedDate.month, 1).weekday;
    
    // Konversi ke index Senin = 0
    firstWeekday = firstWeekday - 1;
    
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildCalendarDay(int day, DateTime date, bool isToday) {
    // Cek status tanggal
    bool isMenstruation = _isDateInList(date, _menstruationDates);
    bool isPrediction = _isDateInList(date, _predictionDates);
    bool isOvulation = _isDateInList(date, _ovulationDates);
    bool hasNote = _hasNoteDates[date] == true;
    
    // Tentukan warna background
    Color? backgroundColor;
    Color textColor = AppColors.textPrimary;
    
    if (isMenstruation) {
      backgroundColor = AppColors.menstruation.withValues(alpha: 0.3);
      textColor = AppColors.menstruation;
    } else if (isPrediction) {
      backgroundColor = AppColors.prediction.withValues(alpha: 0.3);
      textColor = AppColors.prediction;
    } else if (isOvulation) {
      backgroundColor = AppColors.ovulation.withValues(alpha: 0.3);
      textColor = AppColors.ovulation;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        // Tampilkan bottom sheet dengan info tanggal
        _showDateInfoSheet(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: isToday && !isMenstruation && !isPrediction
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            
            // Icon pensil jika ada catatan
            if (hasNote)
              Positioned(
                bottom: 2,
                right: 2,
                child: Icon(
                  Icons.edit_note,
                  size: 8,
                  color: AppColors.primary,
                ),
              ),
            
            // Dot kecil untuk ovulasi
            if (isOvulation && !hasNote)
              Positioned(
                bottom: 2,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ovulation,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  bool _isDateInList(DateTime date, List<DateTime> dateList) {
    return dateList.any((d) => 
        d.year == date.year && 
        d.month == date.month && 
        d.day == date.day);
  }

  void _showDateInfoSheet(DateTime date) {
    String formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id').format(date);
    bool isMenstruation = _isDateInList(date, _menstruationDates);
    bool isPrediction = _isDateInList(date, _predictionDates);
    bool isOvulation = _isDateInList(date, _ovulationDates);
    bool hasNote = _hasNoteDates[date] == true;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // Status haid
            if (isMenstruation)
              _buildInfoRow(Icons.favorite, 'Haid', AppColors.menstruation),
            if (isPrediction)
              _buildInfoRow(Icons.calendar_month, 'Prediksi Haid', AppColors.prediction),
            if (isOvulation)
              _buildInfoRow(Icons.egg, 'Masa Ovulasi', AppColors.ovulation),
            
            const SizedBox(height: 10),
            
            // Catatan
            Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  hasNote ? 'Sudah ada catatan harian' : 'Belum ada catatan',
                  style: TextStyle(color: hasNote ? AppColors.success : Colors.grey),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Tombol Catatan Harian
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyNoteScreen(initialDate: date),
                    ),
                  ).then((_) => _loadNotesForMonth()); // Refresh setelah kembali
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Buat Catatan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          const Spacer(),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD WIDGET
  // ============================================

  Widget _buildCycleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.calendar_month, color: AppColors.primary, size: 28),
                const SizedBox(height: 5),
                Text(
                  '${_summaryData['avgCycleLength']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Text('Hari', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Text('Rata-rata siklus', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey.shade300),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.favorite, color: AppColors.primary, size: 28),
                const SizedBox(height: 5),
                Text(
                  '${_summaryData['daysUntilNext']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const Text('Hari lagi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const Text('Menjelang haid', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengaturan Notifikasi'),
        content: const Text('Fitur notifikasi akan segera hadir!\n'
            'Anda akan mendapatkan pengingat:\n'
            '• 3 hari sebelum perkiraan haid\n'
            '• Hari ovulasi\n'
            '• Pengingat catatan harian'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
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
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Siklusku'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol Notifikasi
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _showNotificationDialog,
            tooltip: 'Notifikasi',
          ),
          // Tombol Profile
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _showProfileDialog,
            tooltip: 'Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadCycleData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Cycle info card
                          _buildCycleInfoCard(),
                          
                          const SizedBox(height: 20),
                          
                          // Prediksi haid berikutnya
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
                                      fontSize: 18,
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
                    Container(
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
                                  _loadNotesForMonth();
                                },
                              ),
                              Column(
                                children: [
                                  Text(
                                    _monthFormat.format(_selectedDate),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dayFormat.format(_selectedDate),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
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
                                  _loadNotesForMonth();
                                },
                              ),
                            ],
                          ),
                          
                          // Day headers (Senin = 1)
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
                          SizedBox(
                            height: 280,
                            child: _buildCalendarGrid(),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Legend
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(AppColors.menstruation, 'Haid'),
                              _buildLegendItem(AppColors.prediction, 'Prediksi'),
                              _buildLegendItem(AppColors.ovulation, 'Ovulasi'),
                              _buildLegendItem(Colors.transparent, 'Ada catatan', hasBorder: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Tombol Catatan Harian
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DailyNoteScreen(),
                                  ),
                                ).then((_) => _loadNotesForMonth());
                              },
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Catatan Harian'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color == Colors.transparent ? Colors.transparent : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: hasBorder || color == Colors.transparent
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}