// lib/screens/prediction_screen.dart
// VERSION FINAL - Sesuai dengan API Laravel yang sudah berhasil di-test
// CATATAN: User TIDAK menginput panjang siklus, cukup input tanggal dan gejala!

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // ============================================
  // CONTROLLER UNTUK INPUT
  // ============================================
  final _dateController = TextEditingController();        // Tanggal haid terakhir (WAJIB)
  final _previousDateController = TextEditingController(); // Tanggal haid sebelumnya (OPSIONAL)
  final _painController = TextEditingController();        // Tingkat nyeri (0-10) WAJIB
  final _stressController = TextEditingController();      // Tingkat stres (0-10) WAJIB
  final _sleepController = TextEditingController();       // Jam tidur (0-24) WAJIB
  final _moodController = TextEditingController();        // Mood (1-10) OPSIONAL

  // State variables
  String _result = "";
  bool _isLoading = false;
  DateTime? _selectedDate;
  DateTime? _selectedPreviousDate;
  
  // Untuk menampilkan/menyembunyikan form tips
  bool _showTips = true;
  
  // Riwayat prediksi
  List<Map<String, dynamic>> _recentPredictions = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat(AppConstants.dateFormatApi).format(_selectedDate!);
    
    // Set default values
    _painController.text = '5';
    _stressController.text = '4';
    _sleepController.text = '7';
    _moodController.text = '7';
    
    _loadPredictionHistory();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _previousDateController.dispose();
    _painController.dispose();
    _stressController.dispose();
    _sleepController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictionHistory() async {
    try {
      final history = await ApiService.getPredictionHistory();
      setState(() {
        _recentPredictions = List<Map<String, dynamic>>.from(history);
      });
    } catch (e) {
      print('Error loading prediction history: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(AppConstants.dateFormatApi).format(picked);
      });
    }
  }

  Future<void> _selectPreviousDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPreviousDate ?? DateTime.now(),
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
      setState(() {
        _selectedPreviousDate = picked;
        _previousDateController.text = DateFormat(AppConstants.dateFormatApi).format(picked);
      });
    }
  }

  void _predict() async {
    // ============================================
    // VALIDASI INPUT WAJIB
    // ============================================
    if (_dateController.text.isEmpty) {
      _showError('Tanggal haid terakhir harus diisi!');
      return;
    }
    
    if (_painController.text.isEmpty) {
      _showError('Tingkat nyeri harus diisi (0-10)!');
      return;
    }
    
    if (_stressController.text.isEmpty) {
      _showError('Tingkat stres harus diisi (0-10)!');
      return;
    }
    
    if (_sleepController.text.isEmpty) {
      _showError('Jam tidur harus diisi (0-24)!');
      return;
    }

    // Validasi nilai
    int painLevel = int.tryParse(_painController.text) ?? 0;
    int stressLevel = int.tryParse(_stressController.text) ?? 0;
    double sleepHours = double.tryParse(_sleepController.text) ?? 7;
    int? moodScore = _moodController.text.isNotEmpty ? int.tryParse(_moodController.text) : null;
    
    if (painLevel < 0 || painLevel > 10) {
      _showError('Tingkat nyeri harus antara 0-10');
      return;
    }
    
    if (stressLevel < 0 || stressLevel > 10) {
      _showError('Tingkat stres harus antara 0-10');
      return;
    }
    
    if (sleepHours < 0 || sleepHours > 24) {
      _showError('Jam tidur harus antara 0-24');
      return;
    }
    
    if (moodScore != null && (moodScore < 1 || moodScore > 10)) {
      _showError('Mood harus antara 1-10');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      // Format tanggal ke format yang benar
      String tanggalHaidTerakhir = _dateController.text;
      String? tanggalHaidBulanSebelumnya = _previousDateController.text.isNotEmpty 
          ? _previousDateController.text 
          : null;
      
      print('📤 Sending prediction request...');
      print('   tanggal_haid_terakhir: $tanggalHaidTerakhir');
      print('   tanggal_haid_bulan_sebelumnya: $tanggalHaidBulanSebelumnya');
      print('   pain_level: $painLevel');
      print('   stress_score: $stressLevel');
      print('   sleep_hours: $sleepHours');
      print('   mood_score: $moodScore');

      // ============================================
      // PANGGIL API PREDIKSI (endpoint /api/mobile/predict)
      // ============================================
      final result = await ApiService.predictCycle(
        tanggalHaidTerakhir: tanggalHaidTerakhir,
        tanggalHaidBulanSebelumnya: tanggalHaidBulanSebelumnya,
        painLevel: painLevel,
        stressScore: stressLevel,
        sleepHours: sleepHours,
        moodScore: moodScore,
      );

      print('📥 Prediction result: $result');

      if (result['success'] == true) {
        final resultData = result['data'];
        setState(() {
          _result = 
              "📊 Prediksi Panjang Siklus: ${resultData['predicted_cycle_length']} hari\n"
              "📅 Perkiraan Haid Berikutnya: ${_formatDateString(resultData['next_period_date'])}\n"
              "🎯 Tingkat Kepercayaan: ${resultData['confidence_level']}\n"
              "📏 Margin Error: ±${resultData['error_margin']} hari\n"
              "💡 ${resultData['message']}";
          _isLoading = false;
        });

        _showSuccess('Prediksi berhasil! 🎉');
        _loadPredictionHistory(); // Refresh history
      } else {
        setState(() {
          _result = "❌ Error: ${result['message']}";
          _isLoading = false;
        });
        _showError(result['message']);
      }
    } catch (e) {
      print('❌ Prediction error: $e');
      setState(() {
        _result = "❌ Error: Gagal terhubung ke server\n\nPastikan:\n1. Laravel berjalan di port 8000\n2. Python AI Service berjalan di port 8001\n3. Token masih valid";
        _isLoading = false;
      });
      _showError('Gagal terhubung ke server: $e');
    }
  }
  
  String _formatDateString(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat(AppConstants.dateFormatDisplay, 'id').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _fillSampleData() {
    setState(() {
      // Set tanggal default (1 bulan yang lalu untuk contoh)
      DateTime oneMonthAgo = DateTime.now().subtract(const Duration(days: 28));
      _selectedDate = oneMonthAgo;
      _dateController.text = DateFormat(AppConstants.dateFormatApi).format(oneMonthAgo);
      
      _painController.text = '5';
      _stressController.text = '4';
      _sleepController.text = '7.5';
      _moodController.text = '7';
      _previousDateController.clear();
      _selectedPreviousDate = null;
    });
    
    _showSuccess('Data contoh telah diisi');
  }

  void _clearForm() {
    setState(() {
      // Reset ke tanggal hari ini
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat(AppConstants.dateFormatApi).format(DateTime.now());
      _previousDateController.clear();
      _selectedPreviousDate = null;
      _painController.text = '5';
      _stressController.text = '4';
      _sleepController.text = '7';
      _moodController.text = '7';
      _result = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Prediksi Haid'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: 'Riwayat Prediksi',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Informasi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Prediksi Siklus Haid',
                    style: TextStyle(
                      fontSize: AppFontSize.xl,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'AI akan memprediksi kapan haid Anda berikutnya',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Form Utama
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Data Wajib',
                    style: TextStyle(fontSize: AppFontSize.lg, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Catatan penting: User tidak input panjang siklus!
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Panjang siklus akan dihitung OTOMATIS dari selisih tanggal. '
                            'Anda tidak perlu menginput panjang siklus!',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),

                  // Tanggal Haid Terakhir (WAJIB)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: AppColors.primary),
                      title: const Text('Tanggal Haid Terakhir *'),
                      subtitle: Text(_dateController.text),
                      trailing: const Icon(Icons.edit, color: AppColors.primary),
                      onTap: _selectDate,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Tanggal Haid Sebelumnya (OPSIONAL)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.calendar_month, color: AppColors.primary.withValues(alpha: 0.6)),
                      title: const Text('Tanggal Haid Sebelumnya (opsional)'),
                      subtitle: Text(_previousDateController.text.isEmpty ? 'Belum diisi (akan menggunakan default 28 hari)' : _previousDateController.text),
                      trailing: const Icon(Icons.edit, color: AppColors.primary),
                      onTap: _selectPreviousDate,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Tingkat Nyeri
                  _buildInputField(
                    controller: _painController,
                    label: '💢 Tingkat Nyeri',
                    hint: '0-10',
                    icon: Icons.local_hospital,
                    tooltip: 'Tingkat nyeri saat haid (0 = tidak sakit, 10 = sangat sakit)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Tingkat Stres
                  _buildInputField(
                    controller: _stressController,
                    label: '😫 Tingkat Stres',
                    hint: '0-10',
                    icon: Icons.bolt,
                    tooltip: 'Tingkat stres selama siklus (0 = tidak stres, 10 = sangat stres)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Jam Tidur
                  _buildInputField(
                    controller: _sleepController,
                    label: '😴 Rata-rata Jam Tidur',
                    hint: '0-24',
                    icon: Icons.nightlight_round,
                    tooltip: 'Rata-rata jam tidur per hari',
                    unit: 'jam',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Mood (Opsional)
                  _buildInputField(
                    controller: _moodController,
                    label: '😊 Rata-rata Mood (opsional)',
                    hint: '1-10',
                    icon: Icons.mood,
                    tooltip: 'Rata-rata mood selama siklus (1 = buruk, 10 = sangat baik)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Tombol Prediksi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Prediksi Sekarang',
                                  style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _fillSampleData,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Contoh Data'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Bersihkan'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Hasil Prediksi
            if (_result.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '✨ Hasil Prediksi AI ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: _result.split('\n').map((line) {
                          IconData iconData;
                          if (line.contains('Panjang Siklus')) {
                            iconData = Icons.timeline;
                          } else if (line.contains('Perkiraan Haid')) {
                            iconData = Icons.calendar_today;
                          } else if (line.contains('Tingkat Kepercayaan')) {
                            iconData = Icons.psychology;
                          } else if (line.contains('Margin Error')) {
                            iconData = Icons.science;
                          } else {
                            iconData = Icons.info_outline;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(iconData, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: const TextStyle(color: Colors.white, fontSize: AppFontSize.md),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          'Prediksi berdasarkan AI Linear Regression (MAE ±1.7 hari)',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: AppFontSize.sm),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Tips (Collapsible)
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: Icon(Icons.lightbulb, color: Colors.amber.shade600),
                  title: const Text(
                    'Tips untuk Prediksi Akurat',
                    style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: _showTips,
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _showTips = expanded;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _buildTipItem('✅ Isi tanggal haid sebelumnya untuk hasil lebih akurat'),
                          _buildTipItem('✅ Semakin lengkap data (stres, tidur, mood) semakin baik prediksi'),
                          _buildTipItem('✅ Catat siklus secara rutin untuk prediksi yang makin akurat'),
                          _buildTipItem('✅ Panjang siklus akan dihitung OTOMATIS, Anda tidak perlu menginputnya'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String tooltip,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: tooltip,
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: unit,
            suffixStyle: TextStyle(color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: AppFontSize.md, color: AppColors.primary)),
          Expanded(
            child: Text(tip, style: TextStyle(color: Colors.grey.shade700, fontSize: AppFontSize.sm)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Riwayat Prediksi'),
        content: _recentPredictions.isEmpty
            ? const Text('Belum ada riwayat prediksi')
            : SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: _recentPredictions.length,
                  itemBuilder: (context, index) {
                    final pred = _recentPredictions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('${pred['predicted_cycle_length'] ?? '-'} hari'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tanggal: ${pred['last_cycle_start_date'] ?? '-'}'),
                            Text('Perkiraan: ${pred['predicted_next_date'] ?? '-'}'),
                          ],
                        ),
                        trailing: Text('${pred['error_margin'] ?? 0} hari error'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Prediksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI memprediksi panjang siklus menggunakan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoBullet('Panjang siklus sebelumnya (dari selisih tanggal)'),
            _buildInfoBullet('Tingkat nyeri (0-10)'),
            _buildInfoBullet('Tingkat stres (0-10)'),
            _buildInfoBullet('Pola tidur (jam/hari)'),
            _buildInfoBullet('Mood (1-10) - opsional'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⚠️ User TIDAK PERNAH menginput panjang siklus!\nPanjang siklus adalah HASIL PREDIKSI AI.',
                style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '✅ Akurasi: MAE ±1.72 hari\n✅ Tingkat kepercayaan: Tinggi',
                style: TextStyle(fontSize: AppFontSize.sm, color: AppColors.success),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}