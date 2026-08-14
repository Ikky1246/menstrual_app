// lib/screens/onboarding/mandatory_form_screen.dart
// REDESAIN TEMA SAKURA/GLASSMORPHISM — logika tidak diubah dari versi sebelumnya

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/screens/onboarding/optional_form_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/utils/constants.dart';

// SakuraColors sudah didefinisikan di login_screen.dart, dipakai ulang di sini
// supaya tidak terjadi duplikasi class saat file-file ini di-import bersamaan.
import 'package:menstrual_app/screens/auth/login_screen.dart';

class MandatoryFormScreen extends StatefulWidget {
  const MandatoryFormScreen({super.key});

  @override
  State<MandatoryFormScreen> createState() => _MandatoryFormScreenState();
}

class _MandatoryFormScreenState extends State<MandatoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================
  // FIELD WAJIB (Sesuai Model - TANPA CYCLE LENGTH!)
  // ============================================
  final _lastPeriodController = TextEditingController();
  final _previousPeriodController = TextEditingController();

  // FIELD YANG DIPERLUKAN MODEL
  double _painLevel = 5; // WAJIB (0-10)
  double _stressLevel = 4; // WAJIB (0-10)
  double _sleepHours = 7; // WAJIB (0-24)
  double _moodLevel = 7; // OPSIONAL (1-10)

  // Field tambahan (disimpan untuk info)
  final _periodDurationController = TextEditingController();

  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  bool _isLoading = false;

  String? _savedCycleMongoId;

  // ===== LOGIKA TIDAK DIUBAH SAMA SEKALI =====
  @override
  void initState() {
    super.initState();
    _periodDurationController.text = '5';
  }

  @override
  void dispose() {
    _lastPeriodController.dispose();
    _previousPeriodController.dispose();
    _periodDurationController.dispose();
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

  // Hitung persentase slider untuk visualisasi progress bar
  double _getPainPercentage() {
    return _painLevel / 10;
  }

  double _getStressPercentage() {
    return _stressLevel / 10;
  }

  double _getSleepPercentage() {
    return (_sleepHours - 4) / 6; // min 4, max 10
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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

    if (picked != null) {
      String displayDate = DateFormat(
        AppConstants.dateFormatDisplay,
        'id',
      ).format(picked);
      controller.text = displayDate;
      onDateSelected(picked);
      setState(() {});
    }
  }

  Future<void> _saveAndContinue() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi tanggal harus diisi
    if (_lastPeriodDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tanggal haid terakhir wajib diisi'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();

      if (user == null || user.idUser == null) {
        throw Exception('User tidak ditemukan. Silakan login kembali.');
      }

      String lastPeriodFormatted = DateFormat(
        AppConstants.dateFormatApi,
      ).format(_lastPeriodDate!);
      String? previousPeriodFormatted = _previousPeriodDate != null
          ? DateFormat(AppConstants.dateFormatApi).format(_previousPeriodDate!)
          : null;

      final result = await CycleService.saveCycle(
        lastPeriodDate: lastPeriodFormatted,
        previousPeriodDate: previousPeriodFormatted,
        cycleLengthDays: 28, // Nilai default sementara
        painLevel: _painLevel.toInt(),
        stressScoreCycle: _stressLevel.toInt(),
        sleepHoursCycle: _sleepHours,
        moodScore: _moodLevel.toInt(),
      );

      if (result['success'] == true) {
        final cycleData = result['data'];

        _savedCycleMongoId =
            cycleData['id']?.toString() ??
            cycleData['id_cycle']?.toString() ??
            cycleData['_id']?.toString();

        final prefs = await SharedPreferences.getInstance();
        if (_savedCycleMongoId != null) {
          await prefs.setString('latest_cycle_id', _savedCycleMongoId!);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          _showOptionalFormDialog();
        }
      } else {
        throw Exception(result['message'] ?? 'Gagal menyimpan data');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data: $e'),
            backgroundColor: AppColors.error,
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
            child: Text(
              'Lewati',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted &&
                    _savedCycleMongoId != null &&
                    _lastPeriodDate != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OptionalFormScreen(
                        cycleId: _savedCycleMongoId!,
                        lastPeriodDate: _lastPeriodDate!,
                        previousPeriodDate: _previousPeriodDate,
                        cycleLengthDays: 28,
                        periodDurationDays:
                            int.tryParse(_periodDurationController.text) ?? 5,
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
              backgroundColor: AppColors.primary,
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
  // ===== AKHIR LOGIKA =====

  // ============================================
  // BUILD UI - REDESAIN TEMA SAKURA/GLASSMORPHISM
  // ============================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Slider width dihitung dgn cara yg sama persis seperti kode asli (70% lebar layar)
    final sliderWidth = screenWidth * 0.7;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient sakura
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SakuraColors.light,
                  Color(0xFFFFF8F7),
                  SakuraColors.light,
                ],
              ),
            ),
          ),

          // Blob dekoratif lembut (meniru radial-gradient di body::before)
          const _RadialBlush(top: 40, left: -40, size: 200),
          const _RadialBlush(top: 200, right: -50, size: 220),
          const _RadialBlush(bottom: 140, left: -30, size: 180),

          Column(
            children: [
              // ===== Header ala TopAppBar glass =====
              _GlassHeader(onBack: () => Navigator.pop(context)),

              // ===== Body scrollable =====
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome / Data Wajib Header (glass card)
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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      SakuraColors.primary,
                                      SakuraColors.light,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SakuraColors.primary.withOpacity(
                                        0.25,
                                      ),
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
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Data Wajib',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: SakuraColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Isi data berikut untuk mulai memantau siklus kesehatanmu.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Data Tanggal Section
                        const _SectionHeader(
                          icon: Icons.calendar_today,
                          label: 'DATA TANGGAL',
                        ),
                        const SizedBox(height: 14),

                        // Tanggal Haid Terakhir
                        _GlassDateField(
                          label: 'Tanggal Haid Terakhir *',
                          controller: _lastPeriodController,
                          hint: 'Pilih tanggal',
                          icon: Icons.calendar_month,
                          iconColor: SakuraColors.primary,
                          onTap: () => _selectDate(
                            context,
                            _lastPeriodController,
                            (date) {
                              _lastPeriodDate = date;
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tanggal haid terakhir wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Tanggal Haid Sebelumnya
                        _GlassDateField(
                          label: 'Tanggal Haid Sebelumnya',
                          controller: _previousPeriodController,
                          hint: 'Pilih tanggal (Opsional)',
                          icon: Icons.calendar_today,
                          iconColor: SakuraColors.primary.withOpacity(0.7),
                          onTap: () => _selectDate(
                            context,
                            _previousPeriodController,
                            (date) {
                              _previousPeriodDate = date;
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 6),
                          child: Text(
                            'Kosongkan jika tidak tahu (akan menggunakan default 28 hari).',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // Kondisi Tubuh Section
                        const _SectionHeader(
                          icon: Icons.monitor_heart,
                          label: 'KONDISI TUBUH',
                        ),
                        const SizedBox(height: 14),

                        // Pain Level Card
                        _SliderCard(
                          title: 'Tingkat Nyeri',
                          badgeText: _getPainLabel(_painLevel),
                          accentColor: SakuraColors.primary,
                          percentage: _getPainPercentage(),
                          sliderWidth: sliderWidth,
                          minLabel: 'Tidak sakit',
                          maxLabel: 'Sangat sakit',
                          onDragUpdate: (dx) {
                            final newValue = (dx / sliderWidth).clamp(0.0, 1.0);
                            setState(() {
                              _painLevel = newValue * 10;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Stress Level Card
                        _SliderCard(
                          title: 'Tingkat Stres',
                          badgeText: _getStressLabel(_stressLevel),
                          accentColor: const Color(0xFFC5447F),
                          percentage: _getStressPercentage(),
                          sliderWidth: sliderWidth,
                          minLabel: 'Rileks',
                          maxLabel: 'Sangat stres',
                          onDragUpdate: (dx) {
                            final newValue = (dx / sliderWidth).clamp(0.0, 1.0);
                            setState(() {
                              _stressLevel = newValue * 10;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // Sleep Card
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
                            setState(() {
                              _sleepHours = 4 + (newValue * 6);
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Promotional Banner
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                SakuraColors.primary,
                                SakuraColors.light,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SakuraColors.primary.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: -30,
                                  right: -30,
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -40,
                                  left: -40,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Pahami Sinyal Tubuhmu',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Setiap siklus memberikan petunjuk unik tentang kesehatan hormonalmu.',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ===== Tombol aksi bawah, fixed dgn fade putih =====
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
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
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

// ============ Widget-widget bantu tampilan ============

/// Header ala TopAppBar dgn efek kaca (blur), meniru header sticky di HTML.
class _GlassHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _GlassHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.6)),
            ),
            boxShadow: [
              BoxShadow(
                color: SakuraColors.primary.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: SakuraColors.primary),
              ),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [SakuraColors.primary, Color(0xFFD81B60)],
                  ).createShader(bounds),
                  child: const Text(
                    'MIRAI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white, // ditimpa ShaderMask
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: SakuraColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu kaca (glassmorphism) untuk elemen umum: header info, input tanggal, dsb.
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: SakuraColors.primary.withOpacity(0.12),
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
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Header seksi (mis. "DATA TANGGAL") dgn ikon, meniru .section-header di HTML.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SakuraColors.primary, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: SakuraColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Input tanggal bergaya kaca dgn label di atas, meniru elemen date picker
/// pada desain baru. Aksi tap (`onTap`) tetap memanggil `_selectDate` yang asli.
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
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SakuraColors.light.withOpacity(0.9)),
            boxShadow: [
              BoxShadow(
                color: SakuraColors.primary.withOpacity(0.06),
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
                color: Colors.grey.shade400,
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

/// Kartu slider kustom (drag manual). Kalkulasi posisi (percentage,
/// sliderWidth, rumus drag `dx / sliderWidth` clamp 0..1) tetap PERSIS
/// sama seperti kode asli — komponen ini murni presentasional.
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
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accentColor.withOpacity(0.25)),
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
          const SizedBox(height: 18),
          SizedBox(
            height: 26,
            // GestureDetector dibuat selebar SizedBox penuh (bukan cuma di
            // thumb) supaya drag mudah dimulai dari mana saja di trek —
            // logika perhitungan posisi (dx/sliderWidth) tetap identik
            // dengan kode asli.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                onDragUpdate(details.localPosition.dx);
              },
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    width: (sliderWidth * percentage).clamp(0.0, sliderWidth),
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Positioned(
                    left: ((sliderWidth * percentage) - 13).clamp(
                      -13.0,
                      sliderWidth - 13,
                    ),
                    top: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor,
                        border: Border.all(color: Colors.white, width: 3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
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
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                maxLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol gradient "Simpan & Lanjutkan" meniru tombol CTA pada desain baru.
class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SakuraColors.primary, Color(0xFFD81B60)],
          ),
          boxShadow: [
            BoxShadow(
              color: SakuraColors.primary.withOpacity(0.35),
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Simpan & Lanjutkan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bercak radial dekoratif untuk background, meniru radial-gradient blush
/// pada body::before di HTML.
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
                SakuraColors.primary.withOpacity(0.10),
                SakuraColors.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
