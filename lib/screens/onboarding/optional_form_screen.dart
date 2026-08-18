// lib/screens/onboarding/optional_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/utils/constants.dart';

class OptionalFormScreen extends StatefulWidget {
  final String cycleId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int cycleLengthDays;
  final int periodDurationDays; // selalu 7 dari mandatory form
  final int painLevel;
  final int stressLevel;
  final double sleepHours;
  final int moodLevel;

  const OptionalFormScreen({
    super.key,
    required this.cycleId,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    required this.cycleLengthDays,
    required this.periodDurationDays,
    required this.painLevel,
    required this.stressLevel,
    required this.sleepHours,
    required this.moodLevel,
  });

  @override
  State<OptionalFormScreen> createState() => _OptionalFormScreenState();
}

class _OptionalFormScreenState extends State<OptionalFormScreen> {
  late int _stressLevel;
  late double _sleepHours;
  late int _moodLevel;

  int _age = 0;
  bool _pcosSelected = false;
  bool _birthControlSelected = false;
  double _weight = 0.0;
  double _height = 0.0;

  String? _selectedMood;
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _commonSymptoms = [
    {'name': 'Kram perut', 'icon': Icons.crisis_alert, 'selected': false},
    {'name': 'Sakit kepala', 'icon': Icons.sick, 'selected': false},
    {'name': 'Lelah', 'icon': Icons.battery_alert, 'selected': false},
    {'name': 'Kembung', 'icon': Icons.air, 'selected': false},
    {'name': 'Payudara nyeri', 'icon': Icons.favorite, 'selected': false},
    {'name': 'Jerawat', 'icon': Icons.face, 'selected': false},
    {'name': 'Mood swing', 'icon': Icons.mood_bad, 'selected': false},
    {'name': 'Sakit punggung', 'icon': Icons.back_hand, 'selected': false},
  ];

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Baik', 'level': 8},
    {'emoji': '😐', 'label': 'Biasa', 'level': 6},
    {'emoji': '😢', 'label': 'Sedih', 'level': 4},
    {'emoji': '😴', 'label': 'Lelah', 'level': 3},
    {'emoji': '😠', 'label': 'Mudah marah', 'level': 2},
  ];

  bool _isLoading = false;
  bool _showWeightHeight = false;

  double get _calculatedBmi => (_weight > 0 && _height > 0)
      ? _weight / ((_height / 100) * (_height / 100))
      : 0.0;

  // Helper untuk mendapatkan userId (int)
  Future<int?> _getUserId() async {
    final user = await AuthService.getCurrentUser();
    return user?.idUser;
  }

  @override
  void initState() {
    super.initState();
    _stressLevel = widget.stressLevel;
    _sleepHours = widget.sleepHours;
    _moodLevel = widget.moodLevel;
    _selectedMood = _closestMoodLabel(_moodLevel);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _closestMoodLabel(int level) {
    Map<String, dynamic> closest = _moods.first;
    int smallestDiff = (level - (closest['level'] as int)).abs();
    for (final mood in _moods) {
      final diff = (level - (mood['level'] as int)).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closest = mood;
      }
    }
    return closest['label'] as String;
  }

  String _getMoodLabel(int level) => _closestMoodLabel(level);

  Future<Map<String, dynamic>> _callWithTokenRetry(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final result = await call();
    if (result['success'] == true) return result;

    if (_isSessionExpiredError(result['message'])) {
      final refreshed = await AuthService.refreshToken();
      if (!refreshed) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }
      final retryResult = await call();
      if (retryResult['success'] != true) {
        throw Exception(retryResult['message']);
      }
      return retryResult;
    } else {
      throw Exception(result['message']);
    }
  }

  Future<bool> _ensureValidToken() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      final refreshed = await AuthService.refreshToken();
      return refreshed;
    }
    return true;
  }

  bool _isSessionExpiredError(dynamic message) {
    final msg = message?.toString().toLowerCase() ?? '';
    return msg.contains('login') ||
        msg.contains('token') ||
        msg.contains('session') ||
        msg.contains('unauthorized') ||
        msg.contains('expired') ||
        msg.contains('invalid token') ||
        msg.contains('authenticated');
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sesi Berakhir', style: TextStyle(color: Color(0xFFFF69B4))),
        content: const Text('Sesi Anda telah berakhir. Silakan login kembali untuk melanjutkan.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF69B4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Login Kembali'),
          ),
        ],
      ),
    );
  }

  String? _validatePhysicalData() {
    if (_weight > 0 && (_weight < 20 || _weight > 300)) {
      return 'Berat badan tidak valid (isi antara 20-300 kg)';
    }
    if (_height > 0 && (_height < 50 || _height > 250)) {
      return 'Tinggi badan tidak valid (isi antara 50-250 cm)';
    }
    return null;
  }

  Future<void> _saveAndContinue() async {
    if (_age <= 0 || _age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia wajib diisi dengan benar (1-100 tahun)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final physicalError = _validatePhysicalData();
    if (physicalError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(physicalError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tokenValid = await _ensureValidToken();
      if (!tokenValid) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan.');
      }

      // 1. Update profil
      await _callWithTokenRetry(
        () => AuthService.updateProfile(
          age: _age,
          weightKg: _weight > 0 ? _weight : null,
          heightCm: _height > 0 ? _height : null,
          pcosDiagnosed: _pcosSelected,
          birthControlUse: _birthControlSelected,
        ),
      );

      final user = await AuthService.getCurrentUser();
      final age = user?.age ?? _age;
      final bmi = _calculatedBmi > 0 ? _calculatedBmi : (user?.bmi ?? 22.0);
      final pcos = user?.pcosDiagnosed ?? _pcosSelected;
      final birthControl = user?.birthControlUse ?? _birthControlSelected;

      // 2. Update cycle via API
      await _callWithTokenRetry(
        () => CycleService.updateCycleWithPrediction(
          cycleId: widget.cycleId,
          lastPeriodDate: DateFormat(AppConstants.dateFormatApi).format(widget.lastPeriodDate),
          previousPeriodDate: widget.previousPeriodDate != null
              ? DateFormat(AppConstants.dateFormatApi).format(widget.previousPeriodDate!)
              : null,
          painLevel: widget.painLevel,
          stressScoreCycle: _stressLevel,
          sleepHoursCycle: _sleepHours,
          moodScore: _moodLevel,
          age: age,
          bmi: bmi,
          pcosDiagnosed: pcos ? 1 : 0,
          birthControlUse: birthControl ? 1 : 0,
        ),
      );

      // 3. Simpan cache kondisi tubuh dengan prefix userId
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${userId}_last_stress_level', _stressLevel);
      await prefs.setDouble('${userId}_last_sleep_hours', _sleepHours);
      await prefs.setInt('${userId}_last_mood_level', _moodLevel);
      // Durasi haid selalu 7 hari, simpan juga untuk berjaga-jaga
      await prefs.setInt('${userId}_period_duration', 7);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data tersimpan! Prediksi AI siap digunakan.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      final errorMsg = e.toString();
      if (_isSessionExpiredError(errorMsg)) {
        if (mounted) _showSessionExpiredDialog();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal: ${errorMsg.replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildChip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    final lightPink = const Color(0xFFFFF0F6);
    final darkPink = const Color(0xFFD81B60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        flexibleSpace: _GlassHeader(
          onBack: () => Navigator.pop(context),
          onSkip: () {
            // Skip: tidak menyimpan perubahan karena nilai default sudah tersimpan dari mandatory form
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
      ),
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF0F6), Colors.white, Colors.white],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          const _RadialBlush(top: 60, right: -40, size: 180),
          const _RadialBlush(bottom: 200, left: -50, size: 200),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSuccessCard(),
                const SizedBox(height: 32),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(Icons.favorite, 'Nyeri: ${widget.painLevel}/10', lightPink, darkPink),
                    _buildChip(Icons.bolt, 'Stres: $_stressLevel/10', const Color(0xFFFFD9DE), const Color(0xFF900038)),
                    _buildChip(Icons.nightlight_round, 'Tidur: ${_sleepHours.toStringAsFixed(1)} jam', const Color(0xFFE2E9EC), const Color(0xFF161D1F)),
                    _buildChip(Icons.sentiment_satisfied, 'Mood: ${_getMoodLabel(_moodLevel)}', const Color(0xFFE2E9EC), const Color(0xFF161D1F)),
                  ],
                ),
                const SizedBox(height: 48),

                Row(
                  children: [
                    Icon(Icons.edit_note, color: primaryPink, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Data Tambahan (Wajib untuk prediksi akurat)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF161d1f),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Isi data berikut agar AI dapat memberikan prediksi yang akurat',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5b3f43),
                  ),
                ),
                const SizedBox(height: 24),

                // Input Usia
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usia *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF69B4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF281719),
                          fontSize: 15,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Usia wajib diisi';
                          }
                          final age = int.tryParse(value) ?? 0;
                          if (age <= 0 || age > 100) {
                            return 'Usia harus antara 1-100 tahun';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() => _age = int.tryParse(value) ?? 0),
                        decoration: InputDecoration(
                          hintText: 'Masukkan usia Anda (tahun)',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: lightPink.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: lightPink.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF69B4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // PCOS
                _GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Apakah didiagnosis PCOS?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF281719),
                          ),
                        ),
                      ),
                      Switch(
                        value: _pcosSelected,
                        onChanged: (val) => setState(() => _pcosSelected = val),
                        activeThumbColor: primaryPink,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Kontrasepsi
                _GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Menggunakan kontrasepsi hormonal?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF281719),
                          ),
                        ),
                      ),
                      Switch(
                        value: _birthControlSelected,
                        onChanged: (val) => setState(() => _birthControlSelected = val),
                        activeThumbColor: primaryPink,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mood
                _GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.mood, color: Color(0xFFFF69B4), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Mood Hari Ini (Opsional)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF281719),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _moods.map((mood) {
                          final isSelected = _selectedMood == mood['label'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMood = mood['label'] as String;
                                _moodLevel = mood['level'] as int;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryPink.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryPink
                                      : lightPink.withValues(alpha: 0.9),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Color(0xFFFF69B4),
                                      ),
                                    ),
                                  Text(
                                    '${mood['emoji']} ${mood['label']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected
                                          ? primaryPink
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Symptoms
                Row(
                  children: const [
                    Icon(Icons.medical_services, color: Color(0xFFFF69B4), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Gejala yang Dirasakan (Opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF281719),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth < 400
                        ? 3
                        : (constraints.maxWidth < 600 ? 4 : 5);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _commonSymptoms.length,
                      itemBuilder: (context, index) {
                        final symptom = _commonSymptoms[index];
                        final isSelected = symptom['selected'] as bool;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => symptom['selected'] = !isSelected),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? primaryPink
                                    : lightPink.withValues(alpha: 0.7),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPink.withValues(alpha: 0.10),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isSelected)
                                  const Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Color(0xFFFF69B4),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryPink.withValues(alpha: 0.15)
                                              : lightPink.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            symptom['icon'] as IconData,
                                            color: isSelected
                                                ? primaryPink
                                                : Colors.grey.shade600,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          symptom['name'] as String,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected
                                                ? primaryPink
                                                : Colors.grey.shade700,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Physical Data
                GestureDetector(
                  onTap: () => setState(() => _showWeightHeight = !_showWeightHeight),
                  child: _GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.fitness_center, color: Color(0xFFFF69B4)),
                            SizedBox(width: 12),
                            Text(
                              'Data Fisik (Opsional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: Color(0xFF281719),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _showWeightHeight ? Icons.expand_less : Icons.chevron_right,
                          color: primaryPink,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showWeightHeight) ...[
                  const SizedBox(height: 14),
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Berat Badan (kg)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF281719),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF281719),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Contoh: 55',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: lightPink.withValues(alpha: 0.9),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: lightPink.withValues(alpha: 0.9),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFF69B4),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) => setState(() => _weight = double.tryParse(value) ?? 0.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tinggi Badan (cm)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF281719),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF281719),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Contoh: 165',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: lightPink.withValues(alpha: 0.9),
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: lightPink.withValues(alpha: 0.9),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFF69B4),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) => setState(() => _height = double.tryParse(value) ?? 0.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_calculatedBmi > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'BMI: ${_calculatedBmi.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF69B4),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Notes
                Row(
                  children: const [
                    Icon(Icons.description, color: Color(0xFFFF69B4), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Catatan Tambahan (Opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF281719),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    maxLength: 500,
                    buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF281719),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Hari ini merasa sangat lelah...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // CTA
                _GradientButton(
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveAndContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF4CAF50),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Dasar Berhasil Disimpan!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF281719),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi data di bawah ini agar prediksi AI semakin akurat.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGET BANTUAN TAMPILAN
// ============================================================

class _GlassHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const _GlassHeader({required this.onBack, required this.onSkip});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    final lightPink = const Color(0xFFFFF0F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: lightPink.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFF69B4)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Data Tambahan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF69B4),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Lewati',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    final lightPink = const Color(0xFFFFF0F6);
    final darkPink = const Color(0xFFD81B60);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lightPink.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: darkPink.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GradientButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF69B4), Color(0xFFFF6B9D)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Selesai & Lihat Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadialBlush extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  const _RadialBlush({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primaryPink.withValues(alpha: 0.08),
                primaryPink.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}