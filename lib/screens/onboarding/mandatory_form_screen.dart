// lib/screens/onboarding/mandatory_form_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/screens/onboarding/optional_form_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/utils/constants.dart';

class MandatoryFormScreen extends StatefulWidget {
  const MandatoryFormScreen({super.key});

  @override
  State<MandatoryFormScreen> createState() => _MandatoryFormScreenState();
}

class _MandatoryFormScreenState extends State<MandatoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _lastPeriodController = TextEditingController();
  final _previousPeriodController = TextEditingController();

  double _painLevel = 5;
  double _stressLevel = 4;
  double _sleepHours = 7;
  final double _moodLevel = 7;

  // ✅ Hapus controller durasi haid

  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  bool _isLoading = false;
  String? _savedCycleMongoId;

  // Untuk scoping key per user
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getCurrentUser();
    _userId = user?.idUser?.toString();
  }

  @override
  void dispose() {
    _lastPeriodController.dispose();
    _previousPeriodController.dispose();
    super.dispose();
  }

  String _getPainLabel(double value) {
    if (value <= 2) return 'Tidak sakit';
    if (value <= 4) return 'Sedikit sakit';
    if (value <= 6) return 'Nyeri sedang';
    if (value <= 8) return 'Nyeri berat';
    return 'Sangat berat';
  }

  String _getStressLabel(double value) {
    if (value <= 2) return 'Sangat rileks';
    if (value <= 4) return 'Sedikit stres';
    if (value <= 6) return 'Stres sedang';
    if (value <= 8) return 'Stres berat';
    return 'Sangat stres';
  }

  double _getPainPercentage() => _painLevel / 10;
  double _getStressPercentage() => _stressLevel / 10;
  double _getSleepPercentage() => (_sleepHours - 4) / 6;

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    Function(DateTime) onDateSelected,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: _CustomPinkCalendarPicker(
            initialDate: DateTime.now(),
            onDateSelected: (picked) {
              final displayDate = DateFormat(
                AppConstants.dateFormatDisplay,
                'id',
              ).format(picked);

              controller.text = displayDate;
              onDateSelected(picked);
              Navigator.pop(dialogContext);
            },
          ),
        );
      },
    );
  }

  int _calculateCycleLengthDays() {
    if (_previousPeriodDate != null && _lastPeriodDate != null) {
      final diff = _lastPeriodDate!.difference(_previousPeriodDate!).inDays;
      if (diff > 0) {
        if (diff < 21) return 21;
        if (diff > 45) return 45;
        return diff;
      }
    }
    return 28;
  }

  Future<void> _saveAndContinue() async {
    debugPrint('🟢 Tombol Simpan & Lanjutkan ditekan!');

    if (_formKey.currentState == null) {
      debugPrint('❌ Form state null, mungkin form belum siap');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form belum siap, silakan coba lagi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Validasi form gagal');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon lengkapi semua field yang wajib diisi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_lastPeriodDate == null) {
      debugPrint('❌ Tanggal haid terakhir belum dipilih');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal haid terakhir wajib diisi'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_previousPeriodDate != null &&
        !_previousPeriodDate!.isBefore(_lastPeriodDate!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tanggal haid sebelumnya harus lebih awal dari tanggal haid terakhir',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Validasi jarak 21-45 hari
    if (_previousPeriodDate != null && _lastPeriodDate != null) {
      final diff = _lastPeriodDate!.difference(_previousPeriodDate!).inDays;
      if (diff > 45) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Jarak antara tanggal haid terakhir dan sebelumnya tidak boleh lebih dari 45 hari. Silakan periksa kembali tanggal yang dipilih.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      if (diff < 21) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Jarak antara tanggal haid terakhir dan sebelumnya terlalu pendek (minimal 21 hari). Silakan periksa kembali tanggal yang dipilih.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('📤 Menyimpan data siklus...');
      final user = await AuthService.getCurrentUser();

      if (user == null || user.idUser == null) {
        throw Exception('User tidak ditemukan. Silakan login kembali.');
      }

      // Ambil userId untuk scoping
      final userId = user.idUser.toString();
      _userId = userId;

      final lastPeriodFormatted = DateFormat(
        AppConstants.dateFormatApi,
      ).format(_lastPeriodDate!);
      final previousPeriodFormatted = _previousPeriodDate != null
          ? DateFormat(AppConstants.dateFormatApi).format(_previousPeriodDate!)
          : null;

      final result = await CycleService.saveCycle(
        lastPeriodDate: lastPeriodFormatted,
        previousPeriodDate: previousPeriodFormatted,
        cycleLengthDays: _calculateCycleLengthDays(),
        painLevel: _painLevel.toInt(),
        stressScoreCycle: _stressLevel.toInt(),
        sleepHoursCycle: _sleepHours,
        moodScore: _moodLevel.toInt(),
      );

      debugPrint('📊 Hasil saveCycle: $result');

      if (result['success'] == true) {
        final cycleData = result['data'];
        if (cycleData == null) {
          throw Exception('Data cycle tidak valid dari server (data kosong).');
        }
        _savedCycleMongoId =
            cycleData['id']?.toString() ??
            cycleData['id_cycle']?.toString() ??
            cycleData['_id']?.toString();

        final prefs = await SharedPreferences.getInstance();
        if (_savedCycleMongoId != null) {
          await prefs.setString('latest_cycle_id', _savedCycleMongoId!);
        }
        await prefs.setBool('has_cycle_data', true);

        // ✅ SIMPAN: kondisi tubuh terbaru dengan key per-user
        // (agar data tidak tercampur antar akun)
        await prefs.setInt('${userId}_last_pain_level', _painLevel.toInt());
        await prefs.setInt('${userId}_last_stress_level', _stressLevel.toInt());
        await prefs.setDouble('${userId}_last_sleep_hours', _sleepHours);
        await prefs.setInt('${userId}_last_mood_level', _moodLevel.toInt());

        // ✅ Hapus penyimpanan durasi haid (hardcode 7 hari di dashboard)

        if (mounted) {
          setState(() => _isLoading = false);
          _showOptionalFormDialog();
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyimpan data: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showOptionalFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lengkapi Data?'),
        content: const Text(
          'Kamu bisa melengkapi data tambahan untuk prediksi yang lebih akurat. '
          'Ingin mengisi sekarang?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              }
            },
            child: Text('Lewati', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted &&
                    _savedCycleMongoId != null &&
                    _lastPeriodDate != null) {
                  // ✅ Durasi haid hardcode 7 hari
                  const int periodDuration = 7;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OptionalFormScreen(
                        cycleId: _savedCycleMongoId!,
                        lastPeriodDate: _lastPeriodDate!,
                        previousPeriodDate: _previousPeriodDate,
                        cycleLengthDays: _calculateCycleLengthDays(),
                        periodDurationDays: periodDuration,
                        painLevel: _painLevel.toInt(),
                        stressLevel: _stressLevel.toInt(),
                        sleepHours: _sleepHours,
                        moodLevel: _moodLevel.toInt(),
                      ),
                    ),
                  );
                } else if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF69B4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Isi Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderWidth = screenWidth * 0.7;
    final primaryPink = const Color(0xFFFF69B4);
    final lightPink = const Color(0xFFFFF0F6);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightPink, const Color(0xFFFFF8F7), lightPink],
              ),
            ),
          ),
          _SakuraPetal(top: 40, left: 20, size: 48, opacity: 0.6),
          _SakuraPetal(top: 130, right: 40, size: 64, opacity: 0.4),
          _SakuraPetal(bottom: 160, left: 80, size: 32, opacity: 0.5),
          _SakuraPetal(bottom: 80, right: 64, size: 56, opacity: 0.3),

          const Positioned(top: 0, left: 0, right: 0, child: _GlassHeader()),

          Positioned(
            top: 90,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 24,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF69B4), Color(0xFFFFB6D9)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPink.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data Wajib',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF69B4),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Isi data berikut untuk mulai memantau siklus kesehatanmu.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    const _SectionHeader(
                      icon: Icons.calendar_month,
                      label: 'DATA TANGGAL',
                    ),
                    const SizedBox(height: 16),

                    _GlassDateField(
                      label: 'Tanggal Haid Terakhir *',
                      controller: _lastPeriodController,
                      hint: 'Pilih tanggal',
                      icon: Icons.event,
                      iconColor: primaryPink,
                      onTap: () =>
                          _selectDate(context, _lastPeriodController, (date) {
                            _lastPeriodDate = date;
                          }),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Tanggal haid terakhir wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _GlassDateField(
                      label: 'Tanggal Haid 2 Bulan Sebelumnya',
                      controller: _previousPeriodController,
                      hint: 'Pilih tanggal (Opsional)',
                      icon: Icons.calendar_today,
                      iconColor: Colors.grey,
                      onTap: () => _selectDate(
                        context,
                        _previousPeriodController,
                        (date) {
                          _previousPeriodDate = date;
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        'Kosongkan jika tidak tahu (akan menggunakan default 28 hari).',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ❌ HAPUS blok Durasi Haid (hardcode 7 hari)

                    const SizedBox(height: 24),

                    const _SectionHeader(
                      icon: Icons.monitor_heart,
                      label: 'KONDISI TUBUH',
                    ),
                    const SizedBox(height: 16),

                    _SliderCard(
                      title: 'Tingkat Nyeri',
                      badgeText: _getPainLabel(_painLevel),
                      accentColor: const Color(0xFFb80049),
                      percentage: _getPainPercentage(),
                      sliderWidth: sliderWidth,
                      minLabel: 'Tidak sakit',
                      maxLabel: 'Sangat sakit',
                      onDragUpdate: (dx) {
                        final newValue = (dx / sliderWidth).clamp(0.0, 1.0);
                        setState(() => _painLevel = newValue * 10);
                      },
                    ),
                    const SizedBox(height: 16),

                    _SliderCard(
                      title: 'Tingkat Stres',
                      badgeText: _getStressLabel(_stressLevel),
                      accentColor: const Color(0xFFc5447f),
                      percentage: _getStressPercentage(),
                      sliderWidth: sliderWidth,
                      minLabel: 'Rileks',
                      maxLabel: 'Sangat stres',
                      onDragUpdate: (dx) {
                        final newValue = (dx / sliderWidth).clamp(0.0, 1.0);
                        setState(() => _stressLevel = newValue * 10);
                      },
                    ),
                    const SizedBox(height: 16),

                    _SliderCard(
                      title: 'Rata-rata Tidur',
                      badgeText: '${_sleepHours.toStringAsFixed(1)} jam',
                      accentColor: const Color(0xFF716066),
                      percentage: _getSleepPercentage(),
                      sliderWidth: sliderWidth,
                      minLabel: 'Kurang',
                      maxLabel: 'Sangat cukup',
                      onDragUpdate: (dx) {
                        final newValue = (dx / sliderWidth).clamp(0.0, 1.0);
                        setState(() => _sleepHours = 4 + (newValue * 6));
                      },
                    ),
                    const SizedBox(height: 28),

                    // Promotional Banner - RESPONSIVE
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth < 360 ? 16 : 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF69B4), Color(0xFFD81B60)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPink.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pahami Sinyal Tubuhmu',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 16 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenWidth < 360 ? 4 : 8),
                              Text(
                                'Setiap siklus memberikan petunjuk unik tentang kesehatan hormonalmu.',
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 12 : 14,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: screenWidth < 360 ? -8 : -16,
                            right: screenWidth < 360 ? -12 : -24,
                            child: SizedBox(
                              width: screenWidth < 360 ? 80 : 120,
                              height: screenWidth < 360 ? 80 : 120,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.9),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: _GradientButton(
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _saveAndContinue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// WIDGET BANTU UI (tidak ada perubahan signifikan, hanya untuk kelengkapan)
// =====================================================================

class _GlassHeader extends StatelessWidget {
  const _GlassHeader();

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 12,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPink.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF69B4), Color(0xFFD81B60)],
                  ).createShader(bounds),
                  child: const Text(
                    'MIRAI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  const _GlassCard({
    required this.child,
    required this.padding,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF69B4), size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Color(0xFFFF69B4),
          ),
        ),
      ],
    );
  }
}

class _GlassDateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  const _GlassDateField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final lightPink = const Color(0xFFFFB6D9);
    final primaryPink = const Color(0xFFFF69B4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: lightPink.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: primaryPink.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF281719),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              suffixIcon: Icon(icon, color: iconColor, size: 20),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String title;
  final String badgeText;
  final Color accentColor;
  final double percentage;
  final double sliderWidth;
  final String minLabel;
  final String maxLabel;
  final ValueChanged<double> onDragUpdate;

  const _SliderCard({
    required this.title,
    required this.badgeText,
    required this.accentColor,
    required this.percentage,
    required this.sliderWidth,
    required this.minLabel,
    required this.maxLabel,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final lightPink = const Color(0xFFFFB6D9);
    return _GlassCard(
      padding: const EdgeInsets.all(22),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF281719),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) =>
                onDragUpdate(details.localPosition.dx),
            onTapDown: (details) => onDragUpdate(details.localPosition.dx),
            child: SizedBox(
              width: sliderWidth,
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 9,
                    child: Container(
                      width: sliderWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        color: lightPink.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    child: Container(
                      width: (sliderWidth * percentage).clamp(0.0, sliderWidth),
                      height: 8,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: ((sliderWidth * percentage) - 13).clamp(
                      -13.0,
                      sliderWidth - 13,
                    ),
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: accentColor,
                          border: Border.all(color: Colors.white, width: 3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF69B4), Color(0xFFD81B60)],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withValues(alpha: 0.35),
              blurRadius: 20,
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
                      'Simpan & Lanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

class _SakuraPetal extends StatelessWidget {
  final double? top, bottom, left, right, size, opacity;
  const _SakuraPetal({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final primaryPink = const Color(0xFFFF69B4);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: opacity!,
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: primaryPink.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// WIDGET KALENDER PINK 3-LEVEL (tidak berubah, hanya copy dari kode asli)
// =====================================================================

enum _CalendarView { day, month, year }

class _CustomPinkCalendarPicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;

  const _CustomPinkCalendarPicker({
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<_CustomPinkCalendarPicker> createState() =>
      _CustomPinkCalendarPickerState();
}

class _CustomPinkCalendarPickerState extends State<_CustomPinkCalendarPicker> {
  _CalendarView _view = _CalendarView.day;
  late int _displayYear;
  late int _displayMonth;
  late int _selectedDate;
  late int _selectedMonth;
  late int _selectedYear;
  late int _decadeStart;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static const Color _pinkPrimary = Color(0xFFFF69B4);
  static const Color _pinkDark = Color(0xFFFF1493);
  static const Color _pinkLight = Color(0xFFFFB6D9);
  static const Color _pinkBg = Color(0xFFFFF0F6);
  static const Color _pinkBg2 = Color(0xFFFFE0F0);

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _displayYear = now.year;
    _displayMonth = now.month;
    _selectedDate = now.day;
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _decadeStart = (now.year ~/ 10) * 10 - 10;
  }

  String _getHeaderTitle() {
    switch (_view) {
      case _CalendarView.day:
        return '${_monthNames[_displayMonth - 1]} $_displayYear';
      case _CalendarView.month:
        return '$_displayYear';
      case _CalendarView.year:
        return '$_decadeStart - ${_decadeStart + 9}';
    }
  }

  void _goPrev() {
    setState(() {
      if (_view == _CalendarView.day) {
        _displayMonth--;
        if (_displayMonth < 1) {
          _displayMonth = 12;
          _displayYear--;
        }
      } else if (_view == _CalendarView.month) {
        _displayYear--;
      } else {
        _decadeStart -= 10;
      }
    });
  }

  void _goNext() {
    setState(() {
      if (_view == _CalendarView.day) {
        _displayMonth++;
        if (_displayMonth > 12) {
          _displayMonth = 1;
          _displayYear++;
        }
      } else if (_view == _CalendarView.month) {
        _displayYear++;
      } else {
        _decadeStart += 10;
      }
    });
  }

  void _goUpLevel() {
    setState(() {
      if (_view == _CalendarView.day) {
        _view = _CalendarView.month;
      } else if (_view == _CalendarView.month) {
        _view = _CalendarView.year;
      }
    });
  }

  Widget _buildDayView() {
    final firstDay = DateTime(_displayYear, _displayMonth, 1);
    final daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;
    final firstWeekday = firstDay.weekday % 7;
    final prevMonthDays = DateTime(_displayYear, _displayMonth, 0).day;
    final today = DateTime.now();

    final List<Widget> cells = [];

    for (int i = firstWeekday - 1; i >= 0; i--) {
      cells.add(_buildDayCell((prevMonthDays - i).toString(), isOtherMonth: true));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isToday = (day == today.day && _displayMonth == today.month && _displayYear == today.year);
      final isSelected = (day == _selectedDate && _displayMonth == _selectedMonth && _displayYear == _selectedYear);

      cells.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = day;
              _selectedMonth = _displayMonth;
              _selectedYear = _displayYear;
            });
            widget.onDateSelected(DateTime(_displayYear, _displayMonth, day));
          },
          child: _buildDayCell(day.toString(), isToday: isToday, isSelected: isSelected),
        ),
      );
    }

    final totalCells = firstWeekday + daysInMonth;
    final remaining = (7 - (totalCells % 7)) % 7;
    for (int i = 1; i <= remaining; i++) {
      cells.add(_buildDayCell(i.toString(), isOtherMonth: true));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _dayNames.map((d) => Expanded(
            child: Text(
              d,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _pinkPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: cells,
        ),
      ],
    );
  }

  Widget _buildDayCell(
    String text, {
    bool isToday = false,
    bool isSelected = false,
    bool isOtherMonth = false,
  }) {
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF666666);
    FontWeight fontWeight = FontWeight.normal;
    final List<BoxShadow> shadows = [];

    if (isOtherMonth) {
      textColor = const Color(0xFFDDDDDD);
    } else if (isToday) {
      bgColor = _pinkPrimary;
      textColor = Colors.white;
      fontWeight = FontWeight.bold;
      shadows.add(
        BoxShadow(
          color: _pinkPrimary.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      );
    } else if (isSelected) {
      bgColor = _pinkLight;
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  Widget _buildMonthView() {
    final today = DateTime.now();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: List.generate(12, (index) {
        final isCurrentMonth = (index + 1 == today.month && _displayYear == today.year);
        return GestureDetector(
          onTap: () {
            setState(() {
              _displayMonth = index + 1;
              _view = _CalendarView.day;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: isCurrentMonth
                  ? const LinearGradient(
                      colors: [_pinkPrimary, _pinkDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [_pinkBg, _pinkBg2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentMonth ? _pinkDark : _pinkLight,
                width: 2,
              ),
              boxShadow: isCurrentMonth
                  ? [
                      BoxShadow(
                        color: _pinkPrimary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              _shortMonthNames[index],
              style: TextStyle(
                color: isCurrentMonth ? Colors.white : const Color(0xFF666666),
                fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYearView() {
    final today = DateTime.now();
    final start = _decadeStart - 2;
    final end = _decadeStart + 11;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: List.generate(end - start + 1, (index) {
        final year = start + index;
        final isCurrentYear = (year == today.year);
        final isInRange = (year >= _decadeStart && year <= _decadeStart + 9);

        return GestureDetector(
          onTap: () {
            setState(() {
              _displayYear = year;
              _view = _CalendarView.month;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: isCurrentYear
                  ? const LinearGradient(
                      colors: [_pinkPrimary, _pinkDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [_pinkBg, _pinkBg2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentYear ? _pinkDark : _pinkLight,
                width: 2,
              ),
              boxShadow: isCurrentYear
                  ? [
                      BoxShadow(
                        color: _pinkPrimary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              year.toString(),
              style: TextStyle(
                color: !isInRange
                    ? const Color(0xFFBBBBBB)
                    : (isCurrentYear ? Colors.white : const Color(0xFF666666)),
                fontWeight: isCurrentYear ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pinkLight, width: 3),
        boxShadow: [
          BoxShadow(
            color: _pinkPrimary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _goUpLevel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_pinkBg, _pinkBg2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _pinkLight, width: 2),
                  ),
                  child: Text(
                    _getHeaderTitle(),
                    style: const TextStyle(
                      color: _pinkPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  _buildNavButton(Icons.keyboard_arrow_up_rounded, _goPrev),
                  const SizedBox(width: 4),
                  _buildNavButton(Icons.keyboard_arrow_down_rounded, _goNext),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey(_view),
              child: _view == _CalendarView.day
                  ? _buildDayView()
                  : _view == _CalendarView.month
                  ? _buildMonthView()
                  : _buildYearView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_pinkBg, _pinkBg2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _pinkLight, width: 2),
        ),
        child: Icon(icon, color: _pinkPrimary, size: 24),
      ),
    );
  }
}