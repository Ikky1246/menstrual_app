// lib/screens/onboarding/mandatory_form_screen.dart
// VERSION UPDATE - Sesuai dengan logika AI yang benar
// CATATAN: Panjang siklus TIDAK DIINPUT USER! (dihitung system atau diprediksi AI)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/screens/onboarding/optional_form_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';

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
              primary: Colors.pink.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String displayDate = DateFormat('dd MMMM yyyy', 'id').format(picked);
      controller.text = displayDate;
      onDateSelected(picked);
      setState(() {});
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validasi tanggal harus diisi
    if (_lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal haid terakhir wajib diisi'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();

      if (user == null || user.idUser == null) {
        throw Exception('User tidak ditemukan. Silakan login kembali.');
      }

      String lastPeriodFormatted = DateFormat('yyyy-MM-dd').format(_lastPeriodDate!);
      String? previousPeriodFormatted = _previousPeriodDate != null
          ? DateFormat('yyyy-MM-dd').format(_previousPeriodDate!)
          : null;

      // ✅ KIRIM DATA DENGAN CYCLE LENGTH DEFAULT 28
      // Panjang siklus akan diupdate nanti setelah prediksi AI
      final result = await CycleService.saveMandatoryData(
        idUser: user.idUser!,
        lastPeriodDate: lastPeriodFormatted,
        previousPeriodDate: previousPeriodFormatted,
        cycleLengthDays: 28,  // Nilai default sementara (akan diupdate AI nanti)
        periodDurationDays: int.parse(_periodDurationController.text),
        painLevel: _painLevel.toInt(),
        stressLevel: _stressLevel.toInt(),
        sleepHours: _sleepHours,
        moodLevel: _moodLevel.toInt(),
      );

      if (result['success'] == true) {
        _savedCycleMongoId = result['cycleId'];

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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOptionalFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Lengkapi Data?'),
        content: const Text(
          'Kamu bisa melengkapi data tambahan untuk prediksi yang lebih akurat. '
          'Ingin mengisi sekarang?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveCycleIdToLocal();
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
              Navigator.pop(context);
              if (mounted && _savedCycleMongoId != null && _lastPeriodDate != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OptionalFormScreen(
                      cycleId: _savedCycleMongoId!,
                      lastPeriodDate: _lastPeriodDate!,
                      previousPeriodDate: _previousPeriodDate,
                      cycleLengthDays: 28,  // Default sementara
                      periodDurationDays: int.parse(_periodDurationController.text),
                      painLevel: _painLevel.toInt(),
                      stressLevel: _stressLevel.toInt(),
                      sleepHours: _sleepHours,
                      moodLevel: _moodLevel.toInt(),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Isi Sekarang'),
          ),
        ],
      ),
    );
  }

  void _saveCycleIdToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_savedCycleMongoId != null) {
      await prefs.setString('latest_cycle_id', _savedCycleMongoId!);
    }
  }

  // ============================================
  // BUILD UI
  // ============================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siklus Haid'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Wajib',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
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

                const SizedBox(height: 30),

                // ============================================
                // SECTION 1: DATA TANGGAL (WAJIB)
                // ============================================
                
                const Text('📅 Data Tanggal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _lastPeriodController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _lastPeriodController, (date) {
                    _lastPeriodDate = date;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Terakhir *',
                    hintText: 'Pilih tanggal',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.pink.shade300),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Tanggal haid terakhir wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: _previousPeriodController,
                  readOnly: true,
                  onTap: () => _selectDate(context, _previousPeriodController, (date) {
                    _previousPeriodDate = date;
                  }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Sebelumnya',
                    hintText: 'Pilih tanggal (opsional)',
                    prefixIcon: Icon(Icons.calendar_month, color: Colors.pink.shade300),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Kosongkan jika tidak tahu',
                  ),
                ),

                const SizedBox(height: 30),

                // ============================================
                // SECTION 2: TINGKAT NYERI (WAJIB)
                // ============================================
                
                const Text('💢 Tingkat Nyeri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tidak sakit', style: TextStyle(fontSize: 12)),
                            const Text('Sangat sakit', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Slider(
                          value: _painLevel,
                          min: 0,
                          max: 10,
                          divisions: 10,
                          activeColor: Colors.pink,
                          label: _painLevel.round().toString(),
                          onChanged: (value) {
                            setState(() => _painLevel = value);
                          },
                        ),
                        Align(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getPainLabel(_painLevel),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ============================================
                // SECTION 3: TINGKAT STRES (WAJIB)
                // ============================================
                
                const Text('😫 Tingkat Stres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Rileks', style: TextStyle(fontSize: 12)),
                            const Text('Sangat stres', style: TextStyle(fontSize: 12)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
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

                const SizedBox(height: 30),

                // ============================================
                // SECTION 4: JAM TIDUR (WAJIB)
                // ============================================
                
                const Text('😴 Rata-rata Jam Tidur per Hari', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text('Data ini WAJIB untuk prediksi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(20),
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

                const SizedBox(height: 20),

                // ============================================
                // SECTION 5: DATA OPSIONAL
                // ============================================
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            'Data Opsional (Isi untuk akurasi lebih baik)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      // Mood Level
                      Text('😊 Mood Secara Umum', style: TextStyle(fontWeight: FontWeight.w500)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sangat buruk', style: TextStyle(fontSize: 12)),
                          const Text('Luar biasa', style: TextStyle(fontSize: 12)),
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
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Lama Haid (Opsional)
                      TextFormField(
                        controller: _periodDurationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Lama Haid (hari)',
                          hintText: 'Contoh: 5',
                          prefixIcon: Icon(Icons.timer, color: Colors.blue.shade300),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.pink.shade700, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Panjang siklus akan dihitung OTOMATIS oleh sistem atau diprediksi AI.\n'
                          'Anda TIDAK perlu menginputnya.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan & Lanjutkan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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