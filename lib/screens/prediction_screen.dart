import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cycle_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // ============================================
  // CONTROLER UNTUK INPUT (BARU)
  // ============================================
  final _dateController = TextEditingController();      // Tanggal haid terakhir
  final _previousDateController = TextEditingController(); // Tanggal haid sebelumnya (opsional)
  final _painController = TextEditingController();      // Tingkat nyeri (0-10)
  final _stressController = TextEditingController();    // Tingkat stres (0-10)
  final _sleepController = TextEditingController();     // Jam tidur (0-24)
  final _moodController = TextEditingController();      // Mood (opsional, 1-10)
  final _ageController = TextEditingController();       // Usia (opsional)
  final _weightController = TextEditingController();    // Berat badan (opsional)
  final _heightController = TextEditingController();    // Tinggi badan (opsional)

  // State variables
  String _result = "";
  bool _isLoading = false;
  DateTime? _selectedDate;
  DateTime? _selectedPreviousDate;
  
  // Untuk pilihan Yes/No
  bool? _pcosDiagnosed;
  bool? _birthControlUse;
  
  // Untuk menampilkan/menyembunyikan form opsional
  bool _showOptionalForm = false;
  
  // Riwayat prediksi
  List<Map<String, dynamic>> _recentPredictions = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _loadLatestCycleData();
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
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestCycleData() async {
    try {
      final result = await CycleService.getLatestCycle();
      if (result['success'] == true && result['cycle'] != null) {
        final cycle = result['cycle'];
        setState(() {
          if (cycle.stressScoreCycle != null) {
            _stressController.text = cycle.stressScoreCycle.toString();
          }
          if (cycle.sleepHoursCycle != null) {
            _sleepController.text = cycle.sleepHoursCycle.toString();
          }
          if (cycle.lastPeriodDate.isNotEmpty) {
            _dateController.text = cycle.lastPeriodDate;
            _selectedDate = DateTime.tryParse(cycle.lastPeriodDate);
          }
        });
      }
    } catch (e) {
      print('Error loading cycle data: $e');
    }
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
              primary: Colors.pink.shade400,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.pink.shade400,
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
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
      setState(() {
        _selectedPreviousDate = picked;
        _previousDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _predict() async {
    // ============================================
    // VALIDASI INPUT WAJIB
    // ============================================
    if (_dateController.text.isEmpty) {
      _showError('Tanggal mulai haid harus diisi!');
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

    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      // ============================================
      // PANGGIL API PREDIKSI DENGAN LOGIKA BARU
      // ============================================
      final result = await ApiService.predictCycle(
        lastCycleStartDate: _selectedDate!,
        previousCycleStartDate: _selectedPreviousDate,
        painLevel: painLevel,
        stressScore: stressLevel,
        sleepHours: sleepHours,
        moodScore: _moodController.text.isNotEmpty ? int.tryParse(_moodController.text) : null,
        age: _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        weightKg: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        heightCm: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
        pcosDiagnosed: _pcosDiagnosed,
        birthControlUse: _birthControlUse,
      );

      if (result['success'] == true) {
        final resultData = result['data'];
        setState(() {
          _result = 
              "📊 Panjang Siklus: ${resultData['predicted_cycle_length']} hari\n"
              "📅 Perkiraan Haid Berikutnya: ${resultData['next_period_date']}\n"
              "🎯 Tingkat Kepercayaan: ${resultData['confidence_level']}\n"
              "📏 Margin Error: ±${resultData['error_margin']} hari";
          _isLoading = false;
        });

        _showSuccess('Prediksi berhasil! 🎉');
        _loadPredictionHistory(); // Refresh history
      } else {
        setState(() {
          _result = "Error: ${result['message']}";
          _isLoading = false;
        });
        _showError(result['message']);
      }
    } catch (e) {
      setState(() {
        _result = "Error: Gagal terhubung ke server";
        _isLoading = false;
      });
      _showError('Gagal terhubung ke server: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _fillSampleData() {
    setState(() {
      _painController.text = '5';
      _stressController.text = '4';
      _sleepController.text = '7';
      _moodController.text = '7';
      _ageController.text = '25';
      _weightController.text = '55';
      _heightController.text = '160';
      _pcosDiagnosed = false;
      _birthControlUse = false;
    });
    
    _showSuccess('Data contoh telah diisi');
  }

  void _clearForm() {
    setState(() {
      _painController.clear();
      _stressController.clear();
      _sleepController.clear();
      _moodController.clear();
      _ageController.clear();
      _weightController.clear();
      _heightController.clear();
      _previousDateController.clear();
      _selectedPreviousDate = null;
      _pcosDiagnosed = null;
      _birthControlUse = null;
      _result = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Prediksi Haid'),
        backgroundColor: Colors.pink,
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withValues(alpha: 0.3),
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
                      fontSize: 20,
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

            const SizedBox(height: 20),

            // Form Utama
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Tanggal Haid Terakhir
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.pink.shade300),
                      title: const Text('Tanggal Mulai Haid BULAN INI *'),
                      subtitle: Text(_dateController.text),
                      trailing: const Icon(Icons.edit, color: Colors.pink),
                      onTap: _selectDate,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Tanggal Haid Sebelumnya (Opsional)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.calendar_month, color: Colors.pink.shade200),
                      title: const Text('Tanggal Mulai Haid BULAN LALU (opsional)'),
                      subtitle: Text(_previousDateController.text.isEmpty ? 'Belum diisi' : _previousDateController.text),
                      trailing: const Icon(Icons.edit, color: Colors.pink),
                      onTap: _selectPreviousDate,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tingkat Nyeri
                  _buildInputField(
                    controller: _painController,
                    label: '💢 Tingkat Nyeri',
                    hint: '0-10',
                    icon: Icons.local_hospital,
                    tooltip: 'Tingkat nyeri saat haid (0 = tidak sakit, 10 = sangat sakit)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: 15),

                  // Tingkat Stres
                  _buildInputField(
                    controller: _stressController,
                    label: '😫 Tingkat Stres',
                    hint: '0-10',
                    icon: Icons.bolt,
                    tooltip: 'Tingkat stres selama siklus (0 = tidak stres, 10 = sangat stres)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: 15),

                  // Jam Tidur
                  _buildInputField(
                    controller: _sleepController,
                    label: '😴 Rata-rata Jam Tidur',
                    hint: '0-24',
                    icon: Icons.nightlight_round,
                    tooltip: 'Rata-rata jam tidur per hari',
                    unit: 'jam',
                  ),

                  const SizedBox(height: 10),

                  // Tombol Tampilkan Form Opsional
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showOptionalForm = !_showOptionalForm;
                      });
                    },
                    icon: Icon(_showOptionalForm ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text(_showOptionalForm ? 'Sembunyikan Data Tambahan' : 'Tampilkan Data Tambahan (Meningkatkan Akurasi)'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.pink.shade700,
                    ),
                  ),

                  // Form Opsional (ditampilkan jika _showOptionalForm = true)
                  if (_showOptionalForm) ...[
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      '📈 Data Tambahan (Opsional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    _buildInputField(
                      controller: _moodController,
                      label: '😊 Rata-rata Mood',
                      hint: '1-10',
                      icon: Icons.mood,
                      tooltip: 'Rata-rata mood selama siklus (1 = buruk, 10 = sangat baik)',
                      unit: 'skala',
                    ),

                    const SizedBox(height: 15),

                    _buildInputField(
                      controller: _ageController,
                      label: '📅 Usia',
                      hint: 'Tahun',
                      icon: Icons.cake,
                      tooltip: 'Usia Anda dalam tahun',
                      unit: 'tahun',
                    ),

                    const SizedBox(height: 15),

                    _buildInputField(
                      controller: _weightController,
                      label: '⚖️ Berat Badan',
                      hint: 'kg',
                      icon: Icons.monitor_weight,
                      tooltip: 'Berat badan Anda',
                      unit: 'kg',
                    ),

                    const SizedBox(height: 15),

                    _buildInputField(
                      controller: _heightController,
                      label: '📏 Tinggi Badan',
                      hint: 'cm',
                      icon: Icons.straighten,
                      tooltip: 'Tinggi badan Anda',
                      unit: 'cm',
                    ),

                    const SizedBox(height: 15),

                    // PCOS
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.pink.shade300),
                        const SizedBox(width: 8),
                        const Text('Apakah Anda didiagnosis PCOS?'),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Ya'),
                          selected: _pcosDiagnosed == true,
                          onSelected: (selected) {
                            setState(() {
                              _pcosDiagnosed = selected;
                            });
                          },
                          selectedColor: Colors.pink.shade100,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tidak'),
                          selected: _pcosDiagnosed == false,
                          onSelected: (selected) {
                            setState(() {
                              _pcosDiagnosed = selected ? false : null;
                            });
                          },
                          selectedColor: Colors.pink.shade100,
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // KB Hormonal
                    Row(
                      children: [
                        Icon(Icons.medication, color: Colors.pink.shade300),
                        const SizedBox(width: 8),
                        const Text('Apakah Anda menggunakan KB hormonal?'),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Ya'),
                          selected: _birthControlUse == true,
                          onSelected: (selected) {
                            setState(() {
                              _birthControlUse = selected;
                            });
                          },
                          selectedColor: Colors.pink.shade100,
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tidak'),
                          selected: _birthControlUse == false,
                          onSelected: (selected) {
                            setState(() {
                              _birthControlUse = selected ? false : null;
                            });
                          },
                          selectedColor: Colors.pink.shade100,
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 25),

                  // Tombol Prediksi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
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
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          foregroundColor: Colors.pink.shade700,
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
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.pink.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.3),
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
                        fontSize: 18,
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
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
                          'Prediksi berdasarkan AI (MAE ±1.7 hari)',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tips
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pink.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Tips untuk Prediksi Akurat',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTipItem('Semakin lengkap data (stres, tidur, mood) semakin akurat prediksi'),
                  _buildTipItem('Isi tanggal haid BULAN LALU untuk hasil lebih baik'),
                  _buildTipItem('Data usia, berat, dan tinggi membantu AI memahami profil Anda'),
                  _buildTipItem('Catat siklus secara rutin untuk prediksi yang makin akurat'),
                ],
              ),
            ),
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
            Icon(icon, color: Colors.pink.shade300, size: 20),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 5),
            Tooltip(
              message: tooltip,
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 5),
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
              borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(tip, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
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
                        subtitle: Text('Perkiraan: ${pred['predicted_next_period'] ?? '-'}'),
                        trailing: Text('${pred['confidence_score'] ?? 0}%'),
                        onTap: () => Navigator.pop(context),
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
              'Prediksi dihitung menggunakan AI (Linear Regression):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoBullet('Panjang siklus sebelumnya (dari selisih tanggal)'),
            _buildInfoBullet('Tingkat nyeri'),
            _buildInfoBullet('Tingkat stres'),
            _buildInfoBullet('Pola tidur'),
            _buildInfoBullet('Mood, usia, BMI, PCOS, KB (opsional)'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⚠️ User TIDAK PERNAH menginput panjang siklus!\nPanjang siklus adalah HASIL PREDIKSI AI.',
                style: TextStyle(fontSize: 12, color: Colors.pink),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '✅ Akurasi: MAE ±1.7 hari\n✅ Tingkat kepercayaan: Tinggi',
                style: TextStyle(fontSize: 12, color: Colors.green),
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
          Icon(Icons.circle, size: 6, color: Colors.pink.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}