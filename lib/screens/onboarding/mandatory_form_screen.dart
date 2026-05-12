// lib/screens/onboarding/mandatory_form_screen.dart
// VERSION FINAL - Dengan navigasi yang sudah diperbaiki

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
    print('📱 MandatoryFormScreen diinisialisasi');
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
  
  String _getMoodLabel(double value) {
    if (value <= 2) return 'Sangat buruk';
    if (value <= 4) return 'Biasa saja';
    if (value <= 6) return 'Cukup baik';
    if (value <= 8) return 'Baik';
    return 'Sangat baik';
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
  print('📝 _saveAndContinue() dipanggil');
  
  if (!_formKey.currentState!.validate()) {
    print('❌ Form tidak valid');
    return;
  }
  
  // Validasi tanggal harus diisi
  if (_lastPeriodDate == null) {
    print('❌ Tanggal haid terakhir belum dipilih');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tanggal haid terakhir wajib diisi'), backgroundColor: AppColors.error),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = await AuthService.getCurrentUser();
    print('👤 User saat ini: ${user?.idUser} - ${user?.name}');

    if (user == null || user.idUser == null) {
      throw Exception('User tidak ditemukan. Silakan login kembali.');
    }

    String lastPeriodFormatted = DateFormat(AppConstants.dateFormatApi).format(_lastPeriodDate!);
    String? previousPeriodFormatted = _previousPeriodDate != null
        ? DateFormat(AppConstants.dateFormatApi).format(_previousPeriodDate!)
        : null;
    
    print('📤 Menyimpan data siklus...');
    print('   last_period_date: $lastPeriodFormatted');
    print('   previous_period_date: $previousPeriodFormatted');
    print('   pain_level: ${_painLevel.toInt()}');
    print('   stress_level: ${_stressLevel.toInt()}');
    print('   sleep_hours: $_sleepHours');
    print('   mood_level: ${_moodLevel.toInt()}');

    // Gunakan saveCycle (endpoint /api/mobile/cycle)
    final result = await CycleService.saveCycle(
      lastPeriodDate: lastPeriodFormatted,
      previousPeriodDate: previousPeriodFormatted,
      cycleLengthDays: 28,  // Nilai default sementara
      painLevel: _painLevel.toInt(),
      stressScoreCycle: _stressLevel.toInt(),
      sleepHoursCycle: _sleepHours,
      moodScore: _moodLevel.toInt(),
    );

    print('📊 Hasil save: ${result['success']}');
    print('   Data: ${result['data']}');

    if (result['success'] == true) {
      // Ambil cycleId dari response
      final cycleData = result['data'];
      
      // 🔴 PRIORITAS: Cari 'id' (MongoDB ObjectId) dulu!
      _savedCycleMongoId = cycleData['id']?.toString() ?? 
                           cycleData['id_cycle']?.toString() ?? 
                           cycleData['_id']?.toString();
      
      print('✅ Cycle ID: $_savedCycleMongoId');
      print('   Full response: $cycleData');
      
      // Simpan ke local
      final prefs = await SharedPreferences.getInstance();
      if (_savedCycleMongoId != null) {
        await prefs.setString('latest_cycle_id', _savedCycleMongoId!);
        print('✅ Cycle ID saved to SharedPreferences: $_savedCycleMongoId');
      } else {
        print('⚠️ WARNING: Cycle ID is NULL! Tidak bisa menyimpan ke local.');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        // Tampilkan dialog pilihan
        _showOptionalFormDialog();
      }
    } else {
      throw Exception(result['message'] ?? 'Gagal menyimpan data');
    }
  } catch (e) {
    print('❌ Error: $e');
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
    print('📱 Menampilkan dialog pilihan');
    print('   cycleId: $_savedCycleMongoId');
    print('   lastPeriodDate: $_lastPeriodDate');
    print('   periodDuration: ${_periodDurationController.text}');
    
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
              print('❌ User memilih LEWATI');
              Navigator.pop(dialogContext);
              // Navigasi ke Dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            },
            child: Text(
              'Lewati',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('✅ User memilih ISI SEKARANG');
              Navigator.pop(dialogContext); // Tutup dialog dulu
              
              // Beri sedikit delay agar dialog benar-benar tertutup
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted && _savedCycleMongoId != null && _lastPeriodDate != null) {
                  print('🚀 Navigasi ke OptionalFormScreen');
                  print('   cycleId: $_savedCycleMongoId');
                  print('   lastPeriodDate: $_lastPeriodDate');
                  
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
                  ).then((_) {
                    print('🔙 Kembali dari OptionalFormScreen');
                  });
                } else {
                  print('❌ Gagal navigasi: parameter null');
                  print('   cycleId: $_savedCycleMongoId');
                  print('   lastPeriodDate: $_lastPeriodDate');
                  
                  // Fallback: langsung ke Dashboard
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
  // BUILD UI
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siklus Haid'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Wajib',
                              style: TextStyle(
                                fontSize: AppFontSize.lg,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Isi data berikut untuk memulai',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ============================================
                // SECTION 1: DATA TANGGAL (WAJIB)
                // ============================================
                
                const Text('📅 Data Tanggal', style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _lastPeriodController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _lastPeriodController, (date) {
                    _lastPeriodDate = date;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Terakhir *',
                    hintText: 'Pilih tanggal',
                    prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Tanggal haid terakhir wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _previousPeriodController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _previousPeriodController, (date) {
                    _previousPeriodDate = date;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Sebelumnya',
                    hintText: 'Pilih tanggal (opsional)',
                    prefixIcon: Icon(Icons.calendar_month, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Kosongkan jika tidak tahu (akan menggunakan default 28 hari)',
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ============================================
                // SECTION 2: TINGKAT NYERI (WAJIB)
                // ============================================
                
                const Text('💢 Tingkat Nyeri', style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: AppFontSize.sm, color: Colors.grey)),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tidak sakit', style: TextStyle(fontSize: AppFontSize.sm)),
                            const Text('Sangat sakit', style: TextStyle(fontSize: AppFontSize.sm)),
                          ],
                        ),
                        Slider(
                          value: _painLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          activeColor: AppColors.primary,
                          label: _painLevel.round().toString(),
                          onChanged: (value) {
                            setState(() => _painLevel = value);
                          },
                        ),
                        Align(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppSpacing.lg),
                            ),
                            child: Text(
                              _getPainLabel(_painLevel),
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ============================================
                // SECTION 3: TINGKAT STRES (WAJIB)
                // ============================================
                
                const Text('😫 Tingkat Stres', style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: AppFontSize.sm, color: Colors.grey)),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rileks', style: TextStyle(fontSize: AppFontSize.sm)),
                            const Text('Sangat stres', style: TextStyle(fontSize: AppFontSize.sm)),
                          ],
                        ),
                        Slider(
                          value: _stressLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          activeColor: Colors.orange,
                          onChanged: (value) => setState(() => _stressLevel = value),
                        ),
                        Align(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(AppSpacing.lg),
                            ),
                            child: Text(
                              _getStressLabel(_stressLevel),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ============================================
                // SECTION 4: JAM TIDUR (WAJIB)
                // ============================================
                
                const Text('😴 Rata-rata Jam Tidur per Hari', style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: AppFontSize.sm, color: Colors.grey)),
                const SizedBox(height: AppSpacing.sm),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _sleepHours,
                                min: 4,
                                max: 10,
                                divisions: 12,
                                activeColor: Colors.teal,
                                onChanged: (value) => setState(() => _sleepHours = value),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(AppSpacing.lg),
                              ),
                              child: Text(
                                '${_sleepHours.toStringAsFixed(1)} jam',
                                style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ============================================
                // SECTION 5: DATA OPSIONAL
                // ============================================
                
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppSpacing.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Data Opsional (Isi untuk akurasi lebih baik)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Mood Level
                      const Text('😊 Mood Secara Umum', style: TextStyle(fontWeight: FontWeight.w500)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sangat buruk', style: TextStyle(fontSize: AppFontSize.sm)),
                          const Text('Luar biasa', style: TextStyle(fontSize: AppFontSize.sm)),
                        ],
                      ),
                      Slider(
                        value: _moodLevel,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: Colors.green,
                        onChanged: (value) => setState(() => _moodLevel = value),
                      ),
                      Align(
                        child: Text(
                          _getMoodLabel(_moodLevel),
                          style: TextStyle(fontSize: AppFontSize.sm, color: Colors.green.shade700),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Lama Haid (Opsional)
                      TextFormField(
                        controller: _periodDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Lama Haid (hari)',
                          hintText: 'Contoh: 5',
                          prefixIcon: Icon(Icons.timer, color: Colors.blue.shade300),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Info box
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(
                        child: Text(
                          'Panjang siklus akan dihitung OTOMATIS oleh sistem atau diprediksi AI.\n'
                          'Anda TIDAK perlu menginputnya.',
                          style: TextStyle(fontSize: AppFontSize.sm),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan & Lanjutkan',
                            style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}