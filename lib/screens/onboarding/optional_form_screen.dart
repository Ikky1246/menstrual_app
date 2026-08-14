// lib/screens/onboarding/optional_form_screen.dart
// REDESAIN TEMA SAKURA — logika (prediksi AI, validasi usia, toggle, dsb) tidak diubah
// FIX: Auto-refresh token jika session expired

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/utils/constants.dart';

// SakuraColors sudah didefinisikan di login_screen.dart, dipakai ulang di sini
// supaya tidak terjadi duplikasi class saat file-file ini di-import bersamaan.
import 'package:menstrual_app/screens/auth/login_screen.dart';

class OptionalFormScreen extends StatefulWidget {
  final String cycleId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int cycleLengthDays;
  final int periodDurationDays;

  // Data dari Mandatory Form
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
  // Data dari mandatory (tidak perlu diisi ulang)
  late int _stressLevel;
  late double _sleepHours;
  late int _moodLevel;

  // Data tambahan untuk profil (WAJIB usia, pilihan PCOS/KB)
  int _age = 0;
  bool _pcosSelected = false;
  bool _birthControlSelected = false;
  double _weight = 0;
  double _height = 0;

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
    {'emoji': '😠', 'label': 'Mudah marah', 'level': 2},
    {'emoji': '😴', 'label': 'Lelah', 'level': 3},
  ];

  bool _isLoading = false;
  bool _showWeightHeight = false;

  // ===== LOGIKA TIDAK DIUBAH SAMA SEKALI =====
  @override
  void initState() {
    super.initState();
    _stressLevel = widget.stressLevel;
    _sleepHours = widget.sleepHours;
    _moodLevel = widget.moodLevel;

    // Konversi mood level ke pilihan yang sesuai
    if (_moodLevel >= 8) {
      _selectedMood = 'Baik';
    } else if (_moodLevel >= 6) {
      _selectedMood = 'Biasa';
    } else if (_moodLevel >= 4) {
      _selectedMood = 'Sedih';
    } else if (_moodLevel >= 2) {
      _selectedMood = 'Mudah marah';
    } else {
      _selectedMood = 'Lelah';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ===== AUTO-REFRESH TOKEN HELPER =====
  Future<bool> _ensureValidToken() async {
    // Cek apakah user masih login
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      // Coba refresh token
      final refreshed = await AuthService.refreshToken();
      return refreshed;
    }
    return true;
  }

  Future<void> _saveAndContinue() async {
    // Validasi usia (wajib diisi)
    if (_age <= 0 || _age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia wajib diisi (1-100 tahun) untuk prediksi akurat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ===== STEP 1: CEK & REFRESH TOKEN =====
      final tokenValid = await _ensureValidToken();
      if (!tokenValid) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      // ===== STEP 2: UPDATE PROFIL USER =====
      final userUpdate = await AuthService.updateProfile(
        age: _age,
        weightKg: _weight > 0 ? _weight : null,
        heightCm: _height > 0 ? _height : null,
        pcosDiagnosed: _pcosSelected,
        birthControlUse: _birthControlSelected,
      );

      if (!userUpdate['success']) {
        // Jika error karena session expired, coba refresh token sekali lagi
        if (_isSessionExpiredError(userUpdate['message'])) {
          final refreshed = await AuthService.refreshToken();
          if (!refreshed) {
            throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
          }
          // Ulangi update profile
          final retryUpdate = await AuthService.updateProfile(
            age: _age,
            weightKg: _weight > 0 ? _weight : null,
            heightCm: _height > 0 ? _height : null,
            pcosDiagnosed: _pcosSelected,
            birthControlUse: _birthControlSelected,
          );
          if (!retryUpdate['success']) {
            throw Exception(retryUpdate['message']);
          }
        } else {
          throw Exception(userUpdate['message']);
        }
      }

      // ===== STEP 3: AMBIL USER TERBARU =====
      final user = await AuthService.getCurrentUser();
      final age = user?.age ?? _age;
      double bmi = user?.bmi ?? 22.0;
      if (_weight > 0 && _height > 0 && bmi == 22.0) {
        bmi = _weight / ((_height / 100) * (_height / 100));
      }
      final pcos = user?.pcosDiagnosed ?? _pcosSelected;
      final birthControl = user?.birthControlUse ?? _birthControlSelected;

      // ===== STEP 4: UPDATE CYCLE DENGAN PREDIKSI AI =====
      final cycleUpdate = await CycleService.updateCycleWithPrediction(
        cycleId: widget.cycleId,
        lastPeriodDate: DateFormat(
          AppConstants.dateFormatApi,
        ).format(widget.lastPeriodDate),
        previousPeriodDate: widget.previousPeriodDate != null
            ? DateFormat(
                AppConstants.dateFormatApi,
              ).format(widget.previousPeriodDate!)
            : null,
        painLevel: widget.painLevel,
        stressScoreCycle: _stressLevel,
        sleepHoursCycle: _sleepHours,
        moodScore: _moodLevel,
        age: age,
        bmi: bmi,
        pcosDiagnosed: pcos ? 1 : 0,
        birthControlUse: birthControl ? 1 : 0,
      );

      if (!cycleUpdate['success']) {
        // Jika error karena session expired
        if (_isSessionExpiredError(cycleUpdate['message'])) {
          final refreshed = await AuthService.refreshToken();
          if (!refreshed) {
            throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
          }
          // Ulangi update cycle
          final retryCycle = await CycleService.updateCycleWithPrediction(
            cycleId: widget.cycleId,
            lastPeriodDate: DateFormat(
              AppConstants.dateFormatApi,
            ).format(widget.lastPeriodDate),
            previousPeriodDate: widget.previousPeriodDate != null
                ? DateFormat(
                    AppConstants.dateFormatApi,
                  ).format(widget.previousPeriodDate!)
                : null,
            painLevel: widget.painLevel,
            stressScoreCycle: _stressLevel,
            sleepHoursCycle: _sleepHours,
            moodScore: _moodLevel,
            age: age,
            bmi: bmi,
            pcosDiagnosed: pcos ? 1 : 0,
            birthControlUse: birthControl ? 1 : 0,
          );
          if (!retryCycle['success']) {
            throw Exception(retryCycle['message']);
          }
        } else {
          throw Exception(cycleUpdate['message']);
        }
      }

      // ===== STEP 5: NAVIGASI KE DASHBOARD =====
      if (mounted) {
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
      setState(() => _isLoading = false);

      final errorMsg = e.toString();
      if (_isSessionExpiredError(errorMsg)) {
        if (mounted) {
          _showSessionExpiredDialog();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Gagal: ${errorMsg.replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ===== HELPER: CEK ERROR SESSION EXPIRED =====
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

  // ===== DIALOG SESSION EXPIRED =====
  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sesi Berakhir',
          style: TextStyle(color: SakuraColors.primary),
        ),
        content: const Text(
          'Sesi Anda telah berakhir. Silakan login kembali untuk melanjutkan.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Hapus semua route dan navigasi ke login
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SakuraColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login Kembali'),
          ),
        ],
      ),
    );
  }

  String _getMoodLabel(int level) {
    if (level >= 8) return 'Baik';
    if (level >= 6) return 'Biasa';
    if (level >= 4) return 'Sedih';
    if (level >= 2) return 'Mudah marah';
    return 'Lelah';
  }
  // ===== AKHIR LOGIKA =====

  // ============================================
  // BUILD UI - REDESAIN TEMA SAKURA
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient sakura, meniru linear-gradient body di HTML
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SakuraColors.light, Colors.white, Colors.white],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          const _RadialBlush(top: 60, right: -40, size: 180),
          const _RadialBlush(bottom: 200, left: -50, size: 200),

          Column(
            children: [
              // ===== Header ala TopAppBar =====
              _GlassHeader(
                onBack: () => Navigator.pop(context),
                onSkip: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
              ),

              // ===== Body scrollable =====
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Success Confirmation Card
                      Container(
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
                              color: const Color(0xFF4CAF50).withOpacity(0.10),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF4CAF50),
                                  size: 22,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data Dasar Sudah Tersimpan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF281719),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildChip(
                                  Icons.favorite,
                                  'Nyeri: ${widget.painLevel}/10',
                                  SakuraColors.light,
                                  SakuraColors.dark,
                                ),
                                _buildChip(
                                  Icons.bolt,
                                  'Stres: $_stressLevel/10',
                                  const Color(0xFFFFD9DE),
                                  const Color(0xFF900038),
                                ),
                                _buildChip(
                                  Icons.nightlight_round,
                                  'Tidur: ${_sleepHours.toStringAsFixed(1)} jam',
                                  const Color(0xFFE2E9EC),
                                  const Color(0xFF161D1F),
                                ),
                                _buildChip(
                                  Icons.sentiment_satisfied,
                                  'Mood: ${_getMoodLabel(_moodLevel)}',
                                  const Color(0xFFE2E9EC),
                                  const Color(0xFF161D1F),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Data Tambahan (Wajib untuk prediksi akurat)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Data Tambahan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: SakuraColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SakuraColors.light.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Wajib untuk prediksi akurat',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: SakuraColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input Usia (WAJIB)
                      _GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Usia *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: SakuraColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF281719),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan usia Anda (tahun)',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: SakuraColors.light.withOpacity(0.9),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: SakuraColors.light.withOpacity(0.9),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: SakuraColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              onChanged: (value) {
                                _age = int.tryParse(value) ?? 0;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pilihan PCOS
                      _GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                              onChanged: (val) =>
                                  setState(() => _pcosSelected = val),
                              activeColor: SakuraColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Pilihan Kontrasepsi
                      _GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                              onChanged: (val) =>
                                  setState(() => _birthControlSelected = val),
                              activeColor: SakuraColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mood Section (tetap opsional)
                      _GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.mood,
                                  color: SakuraColors.primary,
                                  size: 20,
                                ),
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
                                final isSelected =
                                    _selectedMood == mood['label'];
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
                                          ? SakuraColors.primary.withOpacity(
                                              0.1,
                                            )
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? SakuraColors.primary
                                            : SakuraColors.light.withOpacity(
                                                0.9,
                                              ),
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
                                              color: SakuraColors.primary,
                                            ),
                                          ),
                                        Text(
                                          '${mood['emoji']} ${mood['label']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? SakuraColors.primary
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

                      // Symptoms Section (opsional) - logika sama persis, tampilan direstyle
                      Row(
                        children: const [
                          Icon(
                            Icons.medical_services,
                            color: SakuraColors.primary,
                            size: 20,
                          ),
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
                          int crossAxisCount = 4;
                          if (constraints.maxWidth < 400) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth < 600) {
                            crossAxisCount = 4;
                          } else {
                            crossAxisCount = 5;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                                onTap: () {
                                  setState(() {
                                    symptom['selected'] = !isSelected;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? SakuraColors.primary
                                          : SakuraColors.light.withOpacity(0.7),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SakuraColors.primary.withOpacity(
                                          0.10,
                                        ),
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
                                            color: SakuraColors.primary,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 4,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? SakuraColors.primary
                                                          .withOpacity(0.15)
                                                    : SakuraColors.light
                                                          .withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  symptom['icon'] as IconData,
                                                  color: isSelected
                                                      ? SakuraColors.primary
                                                      : Colors.grey.shade600,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? SakuraColors.primary
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

                      // Physical Data Button (opsional)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showWeightHeight = !_showWeightHeight;
                          });
                        },
                        child: _GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.fitness_center,
                                    color: SakuraColors.primary,
                                  ),
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
                                _showWeightHeight
                                    ? Icons.expand_less
                                    : Icons.chevron_right,
                                color: SakuraColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Weight & Height Input (Expandable)
                      if (_showWeightHeight) ...[
                        const SizedBox(height: 14),
                        _GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Berat Badan (kg)',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                        hintText: 'Contoh: 55',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: SakuraColors.light
                                                .withOpacity(0.9),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: SakuraColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        _weight = double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Tinggi Badan (cm)',
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                        hintText: 'Contoh: 165',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: SakuraColors.light
                                                .withOpacity(0.9),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: SakuraColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        _height = double.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_weight > 0 && _height > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'BMI: ${(_weight / ((_height / 100) * (_height / 100))).toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: SakuraColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Notes Section
                      Row(
                        children: const [
                          Icon(
                            Icons.description,
                            color: SakuraColors.primary,
                            size: 20,
                          ),
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
                        padding: EdgeInsets.zero,
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 4,
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

                      // CTA Button
                      _GradientButton(
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _saveAndContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip ringkasan (Nyeri/Stres/Tidur/Mood). Signature & pemanggilan sama
  /// persis dgn kode asli — hanya tampilan yg dipercantik.
  Widget _buildChip(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ Widget-widget bantu tampilan ============

/// Header ala TopAppBar dgn efek kaca ringan, tombol back + judul + "Lewati".
class _GlassHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;
  const _GlassHeader({required this.onBack, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 10,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: SakuraColors.light.withOpacity(0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: SakuraColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: SakuraColors.primary),
              ),
              const Text(
                'Data Tambahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SakuraColors.primary,
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
    );
  }
}

/// Kartu putih dgn border pink lembut & bayangan menonjol, meniru .glass-card
/// pada HTML (di sini "glass-card" solid putih, bukan blur — sesuai CSS aslinya).
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SakuraColors.light.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: SakuraColors.dark.withOpacity(0.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }
}

/// Tombol gradient "Selesai & Lihat Dashboard" meniru tombol CTA desain baru.
class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [SakuraColors.primary, Color(0xFFFF6B9D)],
          ),
          boxShadow: [
            BoxShadow(
              color: SakuraColors.primary.withOpacity(0.35),
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

/// Bercak radial dekoratif lembut, meniru nuansa floating petal di background HTML.
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
                SakuraColors.primary.withOpacity(0.08),
                SakuraColors.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
