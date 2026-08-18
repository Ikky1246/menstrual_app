// lib/screens/dashboard_screen.dart
// Fitur lengkap: merah haid aktual, pink prediksi geser, konfirmasi Ya/Tidak responsif
// Durasi haid HARDCODE = 7 hari (tidak bisa diubah)
// Ovulasi menyesuaikan dengan prediksi terbaru
// Panjang siklus yang ditampilkan = cycleLength (dari database/AI) tanpa offset
// Offset hanya untuk menggeser tanggal prediksi, bukan mengubah panjang siklus
//
// REVISI:
// - Semua SharedPreferences key di-scope per user (pakai prefix userId)
// - Durasi haid = 7 hari (konstanta)
// - Popup konfirmasi haid muncul maksimal 1x/hari, terus berulang tiap hari sampai user konfirmasi
// - Konfirmasi "Ya" membuka date picker (bukan langsung pakai tanggal prediksi)
// - "Belum" menggeser prediksi dengan logika catch-up: prediksi baru = besok (hari ini + 1)
// - "Hari ini" (hijau) selalu menimpa warna lain di kalender
// - Tombol konfirmasi/geser di bottom sheet hanya untuk tanggal <= hari ini

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_note_screen.dart';
import 'profile_screen.dart';
import 'mirai_chat_screen.dart';
import '../services/auth_service.dart';
import '../services/cycle_service.dart';
import '../services/daily_note_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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
  // DURASI HAID HARDCODE = 7 hari
  static const int _periodDuration = 7;
  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  int _cycleLength = 28;
  DateTime? _predictedNextPeriod;
  DateTime? _ovulationDate;

  Map<DateTime, bool> _hasNoteDates = {};
  int _predictionOffsetDays = 0;
  bool _isDialogShowing = false;

  // User ID (int dari API)
  int? _userId;
  String get _userIdPrefix => _userId?.toString() ?? 'unknown';

  // Key names dengan prefix
  String get _kPredictionOffsetKey => '${_userIdPrefix}_prediction_offset';
  String get _kLastPopupShownKey => '${_userIdPrefix}_last_popup_shown_date_v2';
  String get _kLastPainKey => '${_userIdPrefix}_last_pain_level';
  String get _kLastStressKey => '${_userIdPrefix}_last_stress_level';
  String get _kLastSleepKey => '${_userIdPrefix}_last_sleep_hours';
  String get _kLastMoodKey => '${_userIdPrefix}_last_mood_level';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserIdAndData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndShowDailyPopup();
    }
  }

  // ========== INISIALISASI ==========
  Future<void> _loadUserIdAndData() async {
    final user = await AuthService.getCurrentUser();
    if (user?.idUser != null) {
      _userId = user!.idUser;
    } else {
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        final newUser = await AuthService.getCurrentUser();
        _userId = newUser?.idUser;
      }
    }
    await _loadPredictionOffset();
    await _loadCycleData();
  }

  // ========== HELPERS TANGGAL ==========
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDate(DateTime a, DateTime b) {
    final x = _dateOnly(a);
    final y = _dateOnly(b);
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  // ========== OFFSET (per user) ==========
  Future<void> _loadPredictionOffset() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    _predictionOffsetDays = prefs.getInt(_kPredictionOffsetKey) ?? 0;
  }

  Future<void> _savePredictionOffset() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPredictionOffsetKey, _predictionOffsetDays);
  }

  Future<void> _resetPredictionOffset() async {
    if (_predictionOffsetDays != 0) {
      _predictionOffsetDays = 0;
      await _savePredictionOffset();
    }
  }

  // ========== LOAD DATA SIKLUS ==========
  Future<void> _loadCycleData() async {
    if (_userId == null) {
      final refreshed = await AuthService.refreshToken();
      if (refreshed) {
        final user = await AuthService.getCurrentUser();
        _userId = user?.idUser;
      }
      if (_userId == null) {
        if (mounted) _showNoDataDialog();
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final cycleResult = await CycleService.getLatestCycle();
      if (cycleResult['success'] && cycleResult['cycle'] != null) {
        final cycle = cycleResult['cycle'];

        final bool isNewCycle =
            _lastPeriodDate == null || !_isSameDate(_lastPeriodDate!, cycle.lastPeriodDate);

        _lastPeriodDate = cycle.lastPeriodDate;
        _previousPeriodDate = cycle.previousPeriodDate;
        _cycleLength = cycle.cycleLengthDays ?? 28;

        if (isNewCycle) {
          await _resetPredictionOffset();
        } else {
          await _loadPredictionOffset();
        }

        _updatePredictions();
        _calculateSummary();
        _generateEventsForMonth();
        _loadNotesForMonth();

        await _checkAndShowDailyPopup();
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

  // ========== POPUP HARIAN (per user) ==========
  Future<void> _checkAndShowDailyPopup() async {
    if (_predictedNextPeriod == null || !mounted || _isDialogShowing || _userId == null) return;

    final todayOnly = _dateOnly(DateTime.now());
    final predOnly = _dateOnly(_predictedNextPeriod!);

    if (todayOnly.isBefore(predOnly)) {
      debugPrint('🔕 Popup skip: hari ini $todayOnly, prediksi $predOnly (belum masuk)');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(todayOnly);
    final lastShown = prefs.getString(_kLastPopupShownKey);
    debugPrint('🔔 Cek popup harian: today=$todayKey, lastShown=$lastShown');
    if (lastShown == todayKey) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isDialogShowing) return;
      _isDialogShowing = true;
      try {
        await prefs.setString(_kLastPopupShownKey, todayKey);
        debugPrint('✅ Menampilkan popup konfirmasi haid');
        await _showPredictionDialog(predOnly);
      } finally {
        _isDialogShowing = false;
      }
    });
  }

  // ========== UPDATE PREDIKSI ==========
  void _updatePredictions() {
    if (_lastPeriodDate == null) return;
    _predictedNextPeriod = _lastPeriodDate!.add(
      Duration(days: _cycleLength + _predictionOffsetDays)
    );
    _ovulationDate = _predictedNextPeriod!.subtract(const Duration(days: 14));
  }

  DateTime? _findRelevantOvulationDate() {
    if (_lastPeriodDate == null) return null;
    final base = _dateOnly(_lastPeriodDate!);
    final today = _dateOnly(DateTime.now());

    for (int n = 1; n <= 100; n++) {
      final ovulation = base.add(Duration(days: (n * _cycleLength) + _predictionOffsetDays - 14));
      if (!ovulation.isBefore(today)) {
        return ovulation;
      }
    }
    return _ovulationDate;
  }

  void _calculateSummary() {
    final today = _dateOnly(DateTime.now());

    int rawDiff = _predictedNextPeriod != null
        ? _dateOnly(_predictedNextPeriod!).difference(today).inDays
        : 0;

    final bool isOverdue = rawDiff < 0;
    final int daysUntilNext = isOverdue ? 0 : rawDiff;
    final int overdueDays = isOverdue ? -rawDiff : 0;

    int currentDay = _lastPeriodDate != null
        ? today.difference(_dateOnly(_lastPeriodDate!)).inDays + 1
        : 1;
    if (currentDay < 1) currentDay = 1;

    final DateTime? displayedOvulation = _findRelevantOvulationDate();

    setState(() {
      _summaryData = {
        'avgCycleLength': _cycleLength + _predictionOffsetDays,
        'daysUntilNext': daysUntilNext,
        'isOverdue': isOverdue,
        'overdueDays': overdueDays,
        'currentDay': currentDay,
        'nextPeriod': _formatPredictionRange(),
        'ovulationDate': displayedOvulation != null
            ? DateFormat('dd MMMM yyyy', 'id').format(displayedOvulation)
            : '-',
      };
    });
  }

  String _formatPredictionRange() {
    if (_predictedNextPeriod == null) return '-';
    final start = _dateOnly(_predictedNextPeriod!);
    final end = start.add(Duration(days: _periodDuration - 1));

    final endStr = DateFormat('dd MMMM yyyy', 'id').format(end);
    if (start.year == end.year && start.month == end.month) {
      final startStr = DateFormat('dd', 'id').format(start);
      return '$startStr - $endStr';
    }
    final startStr = DateFormat('dd MMMM yyyy', 'id').format(start);
    return '$startStr - $endStr';
  }

  // ========== GENERATE KALENDER ==========
  void _generateEventsForMonth() {
    if (_lastPeriodDate == null) {
      setState(() => _calendarEvents = {});
      return;
    }

    final events = <DateTime, CalendarEventData>{};
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    final lastPeriodOnly = DateTime(_lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);
    final previousPeriodOnly = _previousPeriodDate != null
        ? DateTime(
            _previousPeriodDate!.year,
            _previousPeriodDate!.month,
            _previousPeriodDate!.day,
          )
        : null;

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(year, month, day);
      final key = DateTime(date.year, date.month, date.day);

      // HAID SEBELUMNYA (merah)
      if (previousPeriodOnly != null && key.isAfter(previousPeriodOnly.subtract(const Duration(days: 1)))) {
        int daysSincePrev = key.difference(previousPeriodOnly).inDays;
        if (daysSincePrev >= 0 && daysSincePrev < _periodDuration) {
          events[key] = CalendarEventData(type: CalendarEventType.menstruation);
          continue;
        }
      }

      // HAID SAAT INI (merah)
      if (key.isAfter(lastPeriodOnly.subtract(const Duration(days: 1)))) {
        int daysSinceLast = key.difference(lastPeriodOnly).inDays;
        if (daysSinceLast >= 0 && daysSinceLast < _periodDuration) {
          events[key] = CalendarEventData(type: CalendarEventType.menstruation);
          continue;
        }
      }

      // OVULASI SIKLUS SEBELUMNYA (ungu)
      if (previousPeriodOnly != null) {
        DateTime prevOvulation = previousPeriodOnly.add(
          Duration(days: _cycleLength - 14),
        );
        if (key.year == prevOvulation.year &&
            key.month == prevOvulation.month &&
            key.day == prevOvulation.day) {
          events.putIfAbsent(
            key,
            () => CalendarEventData(type: CalendarEventType.ovulation),
          );
        }
      }

      // OVULASI SIKLUS SAAT INI (ungu)
      DateTime currentOvulation = lastPeriodOnly.add(Duration(days: _cycleLength - 14));
      if (key.year == currentOvulation.year && key.month == currentOvulation.month && key.day == currentOvulation.day) {
        events.putIfAbsent(key, () => CalendarEventData(type: CalendarEventType.ovulation));
      }

      // PREDIKSI HAID (pink)
      if (key.isBefore(lastPeriodOnly)) continue;

      int cycleNumber = 1;
      bool found = false;
      while (!found && cycleNumber <= 100) {
        DateTime predictedStart = lastPeriodOnly.add(
          Duration(days: (cycleNumber * _cycleLength).round() + _predictionOffsetDays)
        );
        if (predictedStart.isAfter(lastDayOfMonth) && cycleNumber > 1) break;

        if (key.isAfter(predictedStart.subtract(const Duration(days: 1)))) {
          DateTime predictedEnd = predictedStart.add(
            Duration(days: _periodDuration - 1),
          );
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

      // OVULASI PREDIKSI (ungu) untuk siklus berikutnya
      int cycleNumberOv = 2;
      while (cycleNumberOv <= 100) {
        DateTime predictedStart = lastPeriodOnly.add(
          Duration(days: (cycleNumberOv * _cycleLength).round() + _predictionOffsetDays)
        );
        if (predictedStart.isAfter(lastDayOfMonth) && cycleNumberOv > 2) break;
        DateTime ovulation = predictedStart.subtract(const Duration(days: 14));
        if (key.year == ovulation.year &&
            key.month == ovulation.month &&
            key.day == ovulation.day) {
          events.putIfAbsent(
            key,
            () => CalendarEventData(type: CalendarEventType.ovulation),
          );
          break;
        }
        if (key.isBefore(ovulation) && cycleNumberOv > 2) break;
        cycleNumberOv++;
      }
    }

    setState(() => _calendarEvents = events);
  }

  // ========== GESER PREDIKSI (Belum Haid) ==========
  Future<void> _shiftPredictionForward() async {
    if (_lastPeriodDate == null) return;

    final todayOnly = _dateOnly(DateTime.now());
    final tomorrow = todayOnly.add(const Duration(days: 1));
    final baselinePredicted = _dateOnly(_lastPeriodDate!).add(Duration(days: _cycleLength));

    setState(() {
      _predictionOffsetDays = tomorrow.difference(baselinePredicted).inDays;
      _updatePredictions();
      _calculateSummary();
      _generateEventsForMonth();
    });
    await _savePredictionOffset();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Prediksi digeser ke ${DateFormat('dd MMMM yyyy', 'id').format(_predictedNextPeriod!)}',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      if (_predictedNextPeriod != null) {
        final nextMonth = DateTime(_predictedNextPeriod!.year, _predictedNextPeriod!.month, 1);
        if (_selectedDate.year != nextMonth.year || _selectedDate.month != nextMonth.month) {
          setState(() {
            _selectedDate = nextMonth;
          });
          _generateEventsForMonth();
          _loadNotesForMonth();
        }
      }
    }
  }

  // ========== KONFIRMASI HAID (Ya) ==========
  Future<void> _confirmPeriodStart(DateTime actualDate) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      int newCycleLength = actualDate.difference(_lastPeriodDate!).inDays;
      if (newCycleLength < 21) newCycleLength = 21;
      if (newCycleLength > 45) newCycleLength = 45;

      final lastPeriodStr = actualDate.toIso8601String().split('T')[0];
      final previousPeriodStr = _lastPeriodDate!.toIso8601String().split('T')[0];

      // Ambil cache kondisi tubuh dengan prefix userId
      final prefs = await SharedPreferences.getInstance();
      final lastPain = prefs.getInt(_kLastPainKey) ?? 5;
      final lastStress = prefs.getInt(_kLastStressKey) ?? 4;
      final lastSleep = prefs.getDouble(_kLastSleepKey) ?? 7.0;
      final lastMood = prefs.getInt(_kLastMoodKey) ?? 7;

      final result = await CycleService.saveCycle(
        lastPeriodDate: lastPeriodStr,
        previousPeriodDate: previousPeriodStr,
        cycleLengthDays: newCycleLength,
        painLevel: lastPain,
        stressScoreCycle: lastStress,
        sleepHoursCycle: lastSleep,
        moodScore: lastMood,
      );

      if (result['success'] && mounted) {
        await _resetPredictionOffset();
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== POPUP KONFIRMASI HARIAN ==========
  Future<void> _showPredictionDialog(DateTime predictedDate) async {
    if (!mounted) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Haid'),
        content: const Text('Apakah Anda sudah mengalami haid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'shift'),
            child: const Text('Belum'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'confirm'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    debugPrint('🩸 Popup konfirmasi haid → user memilih: $action');

    if (action == 'confirm' && mounted) {
      final today = DateTime.now();
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: predictedDate,
        firstDate: predictedDate,
        lastDate: today,
        helpText: 'Pilih tanggal mulai haid',
      );
      if (pickedDate != null && mounted) {
        await _confirmPeriodStart(pickedDate);
      }
    } else if (action == 'shift' && mounted) {
      await _shiftPredictionForward();
    }
  }

  // ========== LAINNYA ==========
  Future<void> _loadNotesForMonth() async {
    if (!mounted) return;
    try {
      final result = await DailyNoteService.getNotesForMonth(
        _selectedDate.year,
        _selectedDate.month,
      );
      if (result['success'] && result['notes'] != null && mounted) {
        final notesMap = result['notes'] as Map<String, bool>;
        final notesDates = <DateTime, bool>{};
        for (var entry in notesMap.entries) {
          final dateParts = entry.key.split('-');
          if (dateParts.length == 3) {
            final date = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
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

  void _showNoDataDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Belum Ada Data'),
          content: const Text('Silakan isi data siklus terlebih dahulu.'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

  // ========== BOTTOM SHEET INFO TANGGAL ==========
  void _showDateInfoSheet(DateTime date) {
    if (!mounted) return;

    final event = _calendarEvents[DateTime(date.year, date.month, date.day)];
    bool hasNote = _hasNoteDates[date] == true;
    String formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id').format(date);
    String status = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.circle_outlined;

    if (event != null) {
      switch (event.type) {
        case CalendarEventType.menstruation:
          status = 'Haid';
          statusColor = Colors.red;
          statusIcon = Icons.favorite;
          break;
        case CalendarEventType.ovulation:
          status = 'Masa Ovulasi';
          statusColor = Colors.purple;
          statusIcon = Icons.egg;
          break;
        case CalendarEventType.prediction:
          status = 'Prediksi Haid';
          statusColor = Colors.pink;
          statusIcon = Icons.calendar_month;
          break;
      }
    }

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
            if (status.isNotEmpty)
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 10),
                  Text(status, style: TextStyle(color: statusColor)),
                ],
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.pink),
                const SizedBox(width: 10),
                Text(
                  hasNote ? 'Ada catatan' : 'Belum ada catatan',
                  style: TextStyle(color: hasNote ? Colors.green : Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (event?.type == CalendarEventType.prediction &&
                !date.isAfter(_dateOnly(DateTime.now())))
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Gunakan mounted di dalam onPressed untuk safety
                        if (mounted) {
                          _confirmPeriodStart(date);
                        }
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Ya, Saya Haid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          _shiftPredictionForward();
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Belum, Geser Prediksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else if (event?.type == CalendarEventType.prediction)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tanggal ini masih perkiraan di masa depan. Konfirmasi baru bisa dilakukan setelah tanggalnya tiba.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DailyNoteScreen(initialDate: date)),
                  ).then((_) => _loadNotesForMonth());
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardContent(),
                const MiraiChatScreen(),
                const ProfileScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _loadCycleData();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profil",
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCycleData();
        _generateEventsForMonth();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    title: 'PANJANG SIKLUS',
                    value: '${_summaryData['avgCycleLength']}',
                    unit: 'hari',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    title: 'HAID BERIKUTNYA',
                    value: (_summaryData['isOverdue'] == true)
                        ? '${_summaryData['overdueDays']}'
                        : '${_summaryData['daysUntilNext']}',
                    unit: (_summaryData['isOverdue'] == true) ? 'hari terlambat' : 'hari lagi',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink.withAlpha(77), width: 12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hari ke-${_summaryData['currentDay']}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  const Text('siklus', style: TextStyle(fontSize: 16, color: Colors.pink)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(
                children: [
                  const Text('Prediksi Haid Berikutnya:', style: TextStyle(fontSize: 16)),
                  Text(
                    _summaryData['nextPeriod'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.egg, color: Colors.pink, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Ovulasi: ${_summaryData['ovulationDate']}',
                          style: const TextStyle(color: Colors.pink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        _dateFormat.format(_selectedDate),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Sen'),
                      Text('Sel'),
                      Text('Rab'),
                      Text('Kam'),
                      Text('Jum'),
                      Text('Sab'),
                      Text('Min'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20,
              runSpacing: 8,
              children: const [
                _LegendItem(color: Colors.red, label: 'Haid'),
                _LegendItem(color: Colors.purple, label: 'Ovulasi'),
                _LegendItem(
                  color: Colors.pink,
                  label: 'Prediksi',
                  isLight: true,
                ),
                _LegendItem(color: Colors.green, label: 'Hari ini'),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyNoteScreen()),
                ).then((_) => _loadNotesForMonth()),
                icon: const Icon(Icons.edit_note),
                label: const Text(
                  'Catatan Harian',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink)),
          Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int startOffset = firstDay.weekday - 1;
    if (startOffset < 0) startOffset += 7;
    const totalCells = 42;
    List<DateTime?> days = List.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      days[startOffset + i] = DateTime(year, month, i + 1);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final date = days[index];
        if (date == null) return Container();
        return GestureDetector(
          onTap: () => _showDateInfoSheet(date),
          child: _buildCalendarDay(date),
        );
      },
    );
  }

  Widget _buildCalendarDay(DateTime date) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final event = _calendarEvents[DateTime(date.year, date.month, date.day)];
    final hasNote = _hasNoteDates[date] == true;

    Color? bgColor;
    Color textColor = Colors.black87;

    if (isToday) {
      bgColor = Colors.green;
      textColor = Colors.white;
    } else if (event != null) {
      switch (event.type) {
        case CalendarEventType.menstruation:
          bgColor = Colors.red;
          textColor = Colors.white;
          break;
        case CalendarEventType.ovulation:
          bgColor = Colors.purple;
          textColor = Colors.white;
          break;
        case CalendarEventType.prediction:
          bgColor = Colors.pink.shade100;
          textColor = Colors.black87;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (hasNote)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.edit_note,
                size: 10,
                color: bgColor == Colors.red || bgColor == Colors.purple || bgColor == Colors.green
                    ? Colors.white
                    : Colors.pink,
              ),
            ),
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
  final Color color;
  final String label;
  final bool isLight;
  const _LegendItem({
    required this.color,
    required this.label,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isLight ? color.withAlpha(77) : color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}