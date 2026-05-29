// lib/screens/onboarding/mandatory_form_screen.dart
// VERSION FINAL - Desain sesuai HTML, overflow fixed

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

  // ============================================
  // FIELD WAJIB (Sesuai Model - TANPA CYCLE LENGTH!)
  // ============================================
  final _lastPeriodController = TextEditingController();
  final _previousPeriodController = TextEditingController();
  
  // FIELD YANG DIPERLUKAN MODEL
  double _painLevel = 5;           // WAJIB (0-10)
  double _stressLevel = 4;         // WAJIB (0-10)
  double _sleepHours = 7;          // WAJIB (0-24)
  double _moodLevel = 7;           // OPSIONAL (1-10)
  
  // Field tambahan (disimpan untuk info)
  final _periodDurationController = TextEditingController();

  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  bool _isLoading = false;

  String? _savedCycleMongoId;

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

  // ============================================
  // HELPER FUNCTIONS
  // ============================================
  
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
      String displayDate = DateFormat(AppConstants.dateFormatDisplay, 'id').format(picked);
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
          const SnackBar(content: Text('Tanggal haid terakhir wajib diisi'), backgroundColor: AppColors.error),
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

      String lastPeriodFormatted = DateFormat(AppConstants.dateFormatApi).format(_lastPeriodDate!);
      String? previousPeriodFormatted = _previousPeriodDate != null
          ? DateFormat(AppConstants.dateFormatApi).format(_previousPeriodDate!)
          : null;

      final result = await CycleService.saveCycle(
        lastPeriodDate: lastPeriodFormatted,
        previousPeriodDate: previousPeriodFormatted,
        cycleLengthDays: 28,  // Nilai default sementara
        painLevel: _painLevel.toInt(),
        stressScoreCycle: _stressLevel.toInt(),
        sleepHoursCycle: _sleepHours,
        moodScore: _moodLevel.toInt(),
      );

      if (result['success'] == true) {
        final cycleData = result['data'];
        
        _savedCycleMongoId = cycleData['id']?.toString() ?? 
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
                if (mounted && _savedCycleMongoId != null && _lastPeriodDate != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OptionalFormScreen(
                        cycleId: _savedCycleMongoId!,
                        lastPeriodDate: _lastPeriodDate!,
                        previousPeriodDate: _previousPeriodDate,
                        cycleLengthDays: 28,
                        periodDurationDays: int.tryParse(_periodDurationController.text) ?? 5,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Isi Sekarang'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // BUILD UI - DESAIN SESUAI HTML (OVERFLOW FIXED)
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sliderWidth = screenWidth * 0.7; // 70% dari lebar layar untuk slider
    
    return Scaffold(
      backgroundColor: const Color(0xFFf4fafd),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFf4fafd).withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFe91663).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Color(0xFFb80049)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Text(
                'MIRAI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFb80049),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert, color: Color(0xFFb80049)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome / Data Wajib Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFe91663).withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFf4dce4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFe2165f),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Data Wajib',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFb80049),
                            ),
                          ),
                          Text(
                            'Isi data berikut untuk mulai memantau siklus kesehatanmu.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5b3f43),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data Tanggal Section
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFb80049), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'DATA TANGGAL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF5b3f43),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tanggal Haid Terakhir
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Tanggal Haid Terakhir *',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFf4dce4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _lastPeriodController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _lastPeriodController, (date) {
                        _lastPeriodDate = date;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: const Icon(Icons.event, color: Color(0xFFb80049)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Tanggal haid terakhir wajib diisi';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Tanggal Haid Sebelumnya
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Tanggal Haid Sebelumnya',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFf4dce4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _previousPeriodController,
                      readOnly: true,
                      onTap: () => _selectDate(context, _previousPeriodController, (date) {
                        _previousPeriodDate = date;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Pilih tanggal (Opsional)',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF5b3f43)),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 4),
                    child: Text(
                      'Kosongkan jika tidak tahu (akan menggunakan default 28 hari).',
                      style: TextStyle(fontSize: 11, color: Color(0xFF5b3f43), fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Kondisi Tubuh Section
              Row(
                children: [
                  const Icon(Icons.monitor_heart, color: Color(0xFFb80049), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'KONDISI TUBUH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF5b3f43),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pain Level Card (overflow fixed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFe91663).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFf4dce4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tingkat Nyeri',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF161d1f)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf4dce4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getPainLabel(_painLevel),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFb80049)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf4dce4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: sliderWidth * _getPainPercentage(),
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFb80049),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Positioned(
                                left: (sliderWidth * _getPainPercentage()) - 12,
                                top: 0,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    final newValue = (details.localPosition.dx / sliderWidth).clamp(0.0, 1.0);
                                    setState(() {
                                      _painLevel = newValue * 10;
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFb80049),
                                      border: Border.all(color: Colors.white, width: 4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Tidak sakit', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                            Text('Sangat sakit', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stress Level Card (overflow fixed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFe91663).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFf4dce4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tingkat Stres',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF161d1f)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFffd9e4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStressLabel(_stressLevel),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF890f50)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf4dce4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: sliderWidth * _getStressPercentage(),
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFc5447f),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Positioned(
                                left: (sliderWidth * _getStressPercentage()) - 12,
                                top: 0,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    final newValue = (details.localPosition.dx / sliderWidth).clamp(0.0, 1.0);
                                    setState(() {
                                      _stressLevel = newValue * 10;
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFc5447f),
                                      border: Border.all(color: Colors.white, width: 4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Rileks', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                            Text('Sangat stres', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sleep Card (overflow fixed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFe91663).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFf4dce4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Rata-rata Tidur',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF161d1f)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe2e9ec),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_sleepHours.toStringAsFixed(1)} jam',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF161d1f)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        SizedBox(
                          height: 24,
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf4dce4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: sliderWidth * _getSleepPercentage(),
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF716066),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Positioned(
                                left: (sliderWidth * _getSleepPercentage()) - 12,
                                top: 0,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    final newValue = (details.localPosition.dx / sliderWidth).clamp(0.0, 1.0);
                                    setState(() {
                                      _sleepHours = 4 + (newValue * 6);
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF716066),
                                      border: Border.all(color: Colors.white, width: 4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Kurang', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                            Text('Sangat cukup', style: TextStyle(fontSize: 12, color: Color(0xFF5b3f43))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Informative Section / Tip Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFe2165f), Color(0xFFc5447f)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pahami Sinyal Tubuhmu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Setiap siklus memberikan petunjuk unik tentang kesehatan hormonalmu.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: -8,
                      right: -16,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
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
      // Bottom Action Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFFf4fafd).withValues(alpha: 0.9),
              const Color(0xFFf4fafd),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFb80049),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 15,
                shadowColor: const Color(0xFFb80049).withValues(alpha: 0.3),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Simpan & Lanjutkan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}