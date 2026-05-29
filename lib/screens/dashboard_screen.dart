// lib/screens/dashboard_screen.dart
// Fitur lengkap: merah haid aktual (termasuk siklus sebelumnya), pink prediksi geser, konfirmasi Ya/Tidak responsif
// Durasi haid default = 7 hari (bisa diubah lewat mandatory form)
// DITAMBAH: Ovulasi untuk siklus sebelumnya dan siklus saat ini

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_note_screen.dart';
import 'profile_screen.dart';
import 'mirai_chat_screen.dart';
import '../services/cycle_service.dart';
import '../services/api_service.dart';
import '../services/daily_note_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('MMMM yyyy', 'id');

  Map<DateTime, CalendarEventData> _calendarEvents = {};
  Map<String, dynamic> _summaryData = {
    'avgCycleLength': 28,
    'daysUntilNext': 0,
    'currentDay': 1,
    'nextPeriod': '-',
    'ovulationDate': '-',
  };
  
  bool _isLoading = true;
  int _periodDuration = 7;
  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  double _predictedCycleLength = 28;
  DateTime? _predictedNextPeriod;
  DateTime? _ovulationDate;
  int _cycleLength = 28;
  
  Map<DateTime, bool> _hasNoteDates = {};
  bool _autoPopupShown = false;
  int _predictionOffsetDays = 0;

  @override
  void initState() {
    super.initState();
    _loadPredictionOffset();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadPeriodDuration();
    await _loadCycleData();
    _checkCorrectionNeeded();
  }

  Future<void> _loadPredictionOffset() async {
    final prefs = await SharedPreferences.getInstance();
    _predictionOffsetDays = prefs.getInt('prediction_offset') ?? 0;
  }

  Future<void> _savePredictionOffset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prediction_offset', _predictionOffsetDays);
  }

  Future<void> _resetPredictionOffset() async {
    _predictionOffsetDays = 0;
    await _savePredictionOffset();
  }

  Future<void> _loadPeriodDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final duration = prefs.getInt('period_duration');
    if (duration != null) {
      setState(() => _periodDuration = duration);
    } else {
      setState(() => _periodDuration = 7);
    }
    debugPrint('🩸 Periode duration: $_periodDuration hari');
  }

  Future<void> _loadCycleData() async {
    setState(() => _isLoading = true);
    try {
      final cycleResult = await CycleService.getLatestCycle();
      if (cycleResult['success'] && cycleResult['cycle'] != null) {
        final cycle = cycleResult['cycle'];
        _lastPeriodDate = cycle.lastPeriodDate;
        _previousPeriodDate = cycle.previousPeriodDate;
        _cycleLength = cycle.cycleLengthDays ?? 28;
        _predictedCycleLength = _cycleLength.toDouble();
        _updatePredictionsManually();
        await _tryGetPredictionFromAI(cycle);
        _calculateSummary();
        _generateEventsForMonth();
        _loadNotesForMonth();

        if (!_autoPopupShown && _isTodayPrediction()) {
          _autoPopupShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPredictionDialog(DateTime.now());
          });
        }
      } else {
        if (mounted) _showNoDataDialog();
      }
    } catch (e) {
      debugPrint('Error loading cycle data: $e');
      if (mounted) _showNoDataDialog();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isTodayPrediction() {
    if (_lastPeriodDate == null) return false;
    final today = DateTime.now();
    final key = DateTime(today.year, today.month, today.day);
    final event = _calendarEvents[key];
    return event?.type == CalendarEventType.prediction;
  }

  void _updatePredictionsManually() {
    if (_lastPeriodDate == null) return;
    _predictedNextPeriod = _lastPeriodDate!.add(Duration(days: _cycleLength + _predictionOffsetDays));
    _ovulationDate = _predictedNextPeriod!.subtract(const Duration(days: 14));
  }

  Future<void> _tryGetPredictionFromAI(dynamic cycle) async {
    if (_lastPeriodDate == null) return;
    try {
      final result = await ApiService.predictCycle(
        tanggalHaidTerakhir: _lastPeriodDate!.toIso8601String().split('T')[0],
        tanggalHaidBulanSebelumnya: cycle.previousPeriodDate?.toIso8601String().split('T')[0],
        painLevel: cycle.painLevel ?? 5,
        stressScore: cycle.stressScoreCycle ?? 4,
        sleepHours: cycle.sleepHoursCycle ?? 7,
        moodScore: cycle.moodScore ?? 7,
      );
      if (result['success'] && mounted) {
        setState(() {
          _predictedCycleLength = result['data']['predicted_cycle_length'].toDouble();
          _predictedNextPeriod = DateTime.parse(result['data']['next_period_date']).add(Duration(days: _predictionOffsetDays));
          _ovulationDate = _predictedNextPeriod!.subtract(const Duration(days: 14));
        });
      }
    } catch (e) {
      debugPrint('AI prediction error: $e');
    }
  }
  
  void _calculateSummary() {
    final today = DateTime.now();
    int daysUntilNext = _predictedNextPeriod != null 
        ? _predictedNextPeriod!.difference(today).inDays 
        : 0;
    if (daysUntilNext < 0) daysUntilNext = 0;
    int currentDay = _lastPeriodDate != null 
        ? today.difference(_lastPeriodDate!).inDays + 1
        : 1;
    if (currentDay < 1) currentDay = 1;
    setState(() {
      _summaryData = {
        'avgCycleLength': _predictedCycleLength.round(),
        'daysUntilNext': daysUntilNext,
        'currentDay': currentDay,
        'nextPeriod': _predictedNextPeriod != null 
            ? DateFormat('dd MMMM yyyy', 'id').format(_predictedNextPeriod!)
            : '-',
        'ovulationDate': _ovulationDate != null
            ? DateFormat('dd MMMM yyyy', 'id').format(_ovulationDate!)
            : '-',
      };
    });
  }
  
  void _generateEventsForMonth() {
    if (_lastPeriodDate == null) {
      setState(() => _calendarEvents = {});
      return;
    }

    final events = <DateTime, CalendarEventData>{};
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    double safePredictedCycle = _predictedCycleLength.clamp(1.0, double.infinity);
    
    final lastPeriodOnly = DateTime(_lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);
    final previousPeriodOnly = _previousPeriodDate != null
        ? DateTime(_previousPeriodDate!.year, _previousPeriodDate!.month, _previousPeriodDate!.day)
        : null;
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(year, month, day);
      final key = DateTime(date.year, date.month, date.day);
      
      // Cek haid sebelumnya (merah)
      if (previousPeriodOnly != null && key.isAfter(previousPeriodOnly.subtract(const Duration(days: 1)))) {
        int daysSincePrev = key.difference(previousPeriodOnly).inDays;
        if (daysSincePrev >= 0 && daysSincePrev < _periodDuration) {
          events[key] = CalendarEventData(type: CalendarEventType.menstruation);
          continue;
        }
      }
      
      // Cek haid saat ini (merah)
      if (key.isAfter(lastPeriodOnly.subtract(const Duration(days: 1)))) {
        int daysSinceLast = key.difference(lastPeriodOnly).inDays;
        if (daysSinceLast >= 0 && daysSinceLast < _periodDuration) {
          events[key] = CalendarEventData(type: CalendarEventType.menstruation);
          continue;
        }
      }
      
      // === OVULASI SIklUS SEBELUMNYA (ungu) ===
      if (previousPeriodOnly != null) {
        DateTime prevOvulation = previousPeriodOnly.add(Duration(days: _cycleLength - 14));
        if (key.year == prevOvulation.year && key.month == prevOvulation.month && key.day == prevOvulation.day) {
          events.putIfAbsent(key, () => CalendarEventData(type: CalendarEventType.ovulation));
        }
      }
      
      // === OVULASI SIKLUS SAAT INI (aktual, tanpa offset) ===
      DateTime currentOvulation = lastPeriodOnly.add(Duration(days: _cycleLength - 14));
      if (key.year == currentOvulation.year && key.month == currentOvulation.month && key.day == currentOvulation.day) {
        events.putIfAbsent(key, () => CalendarEventData(type: CalendarEventType.ovulation));
      }
      
      // Prediksi hanya untuk tanggal >= lastPeriodDate
      if (key.isBefore(lastPeriodOnly)) continue;
      
      // PREDIKSI HAID (PINK)
      int cycleNumber = 1;
      bool found = false;
      while (!found && cycleNumber <= 100) {
        DateTime predictedStart = lastPeriodOnly.add(Duration(days: (cycleNumber * safePredictedCycle).round() + _predictionOffsetDays));
        if (key.isAfter(predictedStart.subtract(const Duration(days: 1)))) {
          DateTime predictedEnd = predictedStart.add(Duration(days: _periodDuration - 1));
          if (key.isBefore(predictedEnd.add(const Duration(days: 1)))) {
            events[key] = CalendarEventData(type: CalendarEventType.prediction);
            found = true;
            break;
          }
        }
        if (key.isBefore(predictedStart) && cycleNumber > 1) break;
        cycleNumber++;
      }
      if (found) continue;
      
      // OVULASI PREDIKSI (UNGU) untuk siklus berikutnya
      cycleNumber = 1;
      while (cycleNumber <= 100) {
        DateTime predictedStart = lastPeriodOnly.add(Duration(days: (cycleNumber * safePredictedCycle).round() + _predictionOffsetDays));
        DateTime ovulation = predictedStart.subtract(const Duration(days: 14));
        if (key.year == ovulation.year && key.month == ovulation.month && key.day == ovulation.day) {
          events.putIfAbsent(key, () => CalendarEventData(type: CalendarEventType.ovulation));
          break;
        }
        if (key.isBefore(ovulation) && cycleNumber > 1) break;
        cycleNumber++;
      }
    }
    
    setState(() => _calendarEvents = events);
  }
  
  Future<void> _shiftPredictionForward() async {
    setState(() {
      _predictionOffsetDays++;
      _predictedNextPeriod = _predictedNextPeriod!.add(Duration(days: 1));
      _ovulationDate = _ovulationDate!.add(Duration(days: 1));
      _calculateSummary();
      _generateEventsForMonth();
    });
    await _savePredictionOffset();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediksi digeser 1 hari ke depan'), backgroundColor: Colors.orange),
      );
    }
  }
  
  Future<void> _confirmPeriodStart(DateTime predictedDate) async {
    if (mounted) {
      setState(() => _isLoading = true);
      try {
        int newCycleLength = predictedDate.difference(_lastPeriodDate!).inDays;
        if (newCycleLength < 21) newCycleLength = 21;
        if (newCycleLength > 45) newCycleLength = 45;
        
        final lastPeriodStr = predictedDate.toIso8601String().split('T')[0];
        final previousPeriodStr = _lastPeriodDate!.toIso8601String().split('T')[0];
        
        await _resetPredictionOffset();
        
        final result = await CycleService.saveCycle(
          lastPeriodDate: lastPeriodStr,
          previousPeriodDate: previousPeriodStr,
          cycleLengthDays: newCycleLength,
          painLevel: 5,
          stressScoreCycle: 4,
          sleepHoursCycle: 7,
          moodScore: 7,
        );
        
        if (result['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Haid dikonfirmasi! Data siklus diperbarui.'), backgroundColor: Colors.green),
          );
          await _loadCycleData();
        } else {
          throw Exception('Gagal menyimpan');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal update: $e'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPredictionDialog(DateTime predictedDate) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Haid'),
        content: Text('Apakah Anda mengalami haid pada tanggal ${DateFormat('dd MMMM yyyy', 'id').format(predictedDate)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'shift'),
            child: const Text('Belum, Geser'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Saya Haid'),
          ),
        ],
      ),
    );
    if (action == 'confirm') {
      await _confirmPeriodStart(predictedDate);
    } else if (action == 'shift') {
      await _shiftPredictionForward();
    }
  }
  
  Future<void> _loadNotesForMonth() async {
    if (!mounted) return;
    try {
      final result = await DailyNoteService.getNotesForMonth(_selectedDate.year, _selectedDate.month);
      if (result['success'] && result['notes'] != null && mounted) {
        final notesMap = result['notes'] as Map<String, bool>;
        final notesDates = <DateTime, bool>{};
        for (var entry in notesMap.entries) {
          final dateParts = entry.key.split('-');
          if (dateParts.length == 3) {
            final date = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
            notesDates[date] = true;
          }
        }
        setState(() => _hasNoteDates = notesDates);
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }
  
  void _changeMonth(int delta) {
    setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + delta, 1));
    _generateEventsForMonth();
    _loadNotesForMonth();
  }
  
  Future<void> _checkCorrectionNeeded() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (_lastPeriodDate == null) return;
    final today = DateTime.now();
    if (today.difference(_lastPeriodDate!).inDays > _cycleLength + 5) {
      _showCorrectionNeededDialog();
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
          TextButton(onPressed: () { Navigator.pop(context); _showDatePickerForCorrection(); }, child: const Text('Sudah')),
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Belum')),
        ],
      ),
    );
  }

  void _showDatePickerForCorrection() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 10)),
      lastDate: DateTime.now(),
    );
    if (selectedDate != null) _saveCorrection(selectedDate);
  }

  Future<void> _saveCorrection(DateTime actualStartDate) async {
    try {
      final result = await CycleService.getLatestCycle();
      if (result['success'] && result['cycle'] != null && mounted) {
        final cycle = result['cycle'];
        await CycleService.submitCorrection(
          expectedStartDate: cycle.lastPeriodDate.add(Duration(days: _cycleLength)),
          actualStartDate: actualStartDate,
          correctionType: 'start',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data siklus diperbarui'), backgroundColor: Colors.green));
          await _loadCycleData();
        }
      }
    } catch (e) { debugPrint('Correction error: $e'); }
  }

  void _showNoDataDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Belum Ada Data'),
          content: const Text('Silakan isi data siklus terlebih dahulu.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/mandatory');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Isi Sekarang'),
            ),
          ],
        ),
      );
    });
  }

  void _showDateInfoSheet(DateTime date) {
    final event = _calendarEvents[DateTime(date.year, date.month, date.day)];
    bool hasNote = _hasNoteDates[date] == true;
    String formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id').format(date);
    String status = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.circle_outlined;
    
    if (event != null) {
      switch (event.type) {
        case CalendarEventType.menstruation:
          status = 'Haid'; statusColor = Colors.red; statusIcon = Icons.favorite; break;
        case CalendarEventType.ovulation:
          status = 'Masa Ovulasi'; statusColor = Colors.purple; statusIcon = Icons.egg; break;
        case CalendarEventType.prediction:
          status = 'Prediksi Haid'; statusColor = Colors.pink; statusIcon = Icons.calendar_month; break;
      }
    }
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(formattedDate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (status.isNotEmpty) Row(children: [Icon(statusIcon, color: statusColor), const SizedBox(width: 10), Text(status, style: TextStyle(color: statusColor))]),
            const SizedBox(height: 10),
            Row(children: [Icon(Icons.edit_note, color: Colors.pink), const SizedBox(width: 10), Text(hasNote ? 'Ada catatan' : 'Belum ada catatan', style: TextStyle(color: hasNote ? Colors.green : Colors.grey))]),
            const SizedBox(height: 20),
            
            if (event?.type == CalendarEventType.prediction)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmPeriodStart(date);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Ya, Saya Haid'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _shiftPredictionForward();
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Belum, Geser Prediksi'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DailyNoteScreen(initialDate: date))).then((_) => _loadNotesForMonth());
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Buat Catatan'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('MIRAI', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.pink), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.pink), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardContent(),
                const DailyNoteScreen(),
                const MiraiChatScreen(),
                const ProfileScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: "Catatan"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildComingSoonScreen(String title, String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(message, style: TextStyle(color: Colors.grey.shade600)),
    ]));
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async { await _loadCycleData(); _generateEventsForMonth(); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInfoCard(title: 'PANJANG SIKLUS', value: '${_summaryData['avgCycleLength']}', unit: 'hari')),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(title: 'HAID BERIKUTNYA', value: '${_summaryData['daysUntilNext']}', unit: 'hari lagi')),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.pink.withValues(alpha: 0.3), width: 12)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Hari ke-${_summaryData['currentDay']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink)),
                const Text('siklus', style: TextStyle(fontSize: 16, color: Colors.pink)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(children: [
                const Text('Prediksi Haid Berikutnya:', style: TextStyle(fontSize: 16)),
                Text(_summaryData['nextPeriod'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.pink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.egg, color: Colors.pink, size: 18),
                    const SizedBox(width: 6),
                    Text('Ovulasi: ${_summaryData['ovulationDate']}', style: const TextStyle(color: Colors.pink)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                  Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
                ]),
                const SizedBox(height: 12),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  Text('Sen'), Text('Sel'), Text('Rab'), Text('Kam'), Text('Jum'), Text('Sab'), Text('Min')
                ]),
                const SizedBox(height: 8),
                _buildCalendarGrid(),
              ]),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: const [
                _LegendItem(color: Colors.red, label: 'Haid'),
                _LegendItem(color: Colors.purple, label: 'Ovulasi'),
                _LegendItem(color: Colors.pink, label: 'Prediksi', isLight: true),
                _LegendItem(color: Colors.green, label: 'Hari ini'),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyNoteScreen())).then((_) => _loadNotesForMonth()),
                icon: const Icon(Icons.edit_note),
                label: const Text('Catatan Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required String unit}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink)),
        Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int startOffset = firstDay.weekday - 2;
    if (startOffset < 0) startOffset += 7;
    const totalCells = 42;
    List<DateTime?> days = List.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      days[startOffset + i] = DateTime(year, month, i + 1);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final date = days[index];
        if (date == null) return Container();
        return GestureDetector(onTap: () => _showDateInfoSheet(date), child: _buildCalendarDay(date));
      },
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
    final event = _calendarEvents[DateTime(date.year, date.month, date.day)];
    final hasNote = _hasNoteDates[date] == true;
    
    Color? bgColor;
    Color textColor = Colors.black87;
    if (event != null) {
      switch (event.type) {
        case CalendarEventType.menstruation: bgColor = Colors.red; textColor = Colors.white; break;
        case CalendarEventType.ovulation: bgColor = Colors.purple; textColor = Colors.white; break;
        case CalendarEventType.prediction: bgColor = Colors.pink.shade100; textColor = Colors.black87; break;
      }
    }
    if (isToday && event == null) { bgColor = Colors.green; textColor = Colors.white; }
    
    return Container(
      margin: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(child: Text(date.day.toString(), style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)))),
          if (hasNote)
            Positioned(bottom: 0, right: 0,
              child: Icon(Icons.edit_note, size: 10, color: bgColor == Colors.red || bgColor == Colors.purple ? Colors.white : Colors.pink)),
        ],
      ),
    );
  }
}

enum CalendarEventType { menstruation, ovulation, prediction }

class CalendarEventData {
  final CalendarEventType type;
  CalendarEventData({required this.type});
}

class _LegendItem extends StatelessWidget {
  final Color color; final String label; final bool isLight;
  const _LegendItem({required this.color, required this.label, this.isLight = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: isLight ? color.withValues(alpha: 0.3) : color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }
}