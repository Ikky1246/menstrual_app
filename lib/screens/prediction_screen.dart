import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  // Controllers
  final _cycleController = TextEditingController();
  final _stressController = TextEditingController();
  final _sleepController = TextEditingController();
  final _healthController = TextEditingController();
  final _dateController = TextEditingController();

  // State variables
  String _result = "";
  bool _isLoading = false;
  DateTime? _selectedDate;
  
  // Data historis (dummy, nanti dari API/SharedPreferences)
  final List<Map<String, dynamic>> _recentPredictions = [
    {
      'date': '2026-03-06',
      'cycle': 28,
      'next': '2026-04-03',
      'accuracy': 'Tepat',
    },
    {
      'date': '2026-02-06',
      'cycle': 29,
      'next': '2026-03-07',
      'accuracy': '+1 hari',
    },
    {
      'date': '2026-01-05',
      'cycle': 27,
      'next': '2026-02-01',
      'accuracy': '-1 hari',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default date ke hari ini
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _stressController.dispose();
    _sleepController.dispose();
    _healthController.dispose();
    _dateController.dispose();
    super.dispose();
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

  void _predict() async {
    // Validasi input
    if (_cycleController.text.isEmpty ||
        _stressController.text.isEmpty ||
        _sleepController.text.isEmpty ||
        _healthController.text.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua field harus diisi!'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = "";
    });

    try {
      final data = await ApiService.predictCycle(
        cycleLength: int.parse(_cycleController.text),
        stress: int.parse(_stressController.text),
        sleep: int.parse(_sleepController.text),
        health: int.parse(_healthController.text),
        startDate: _dateController.text,
      );

      setState(() {
        _result = 
            "Siklus: ${data['predicted_cycle_length']} hari\n"
            "Tanggal berikutnya: ${data['next_period_date']}";
        _isLoading = false;
      });

      // Tampilkan sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prediksi berhasil! 🎉'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

    } catch (e) {
      setState(() {
        _result = "Error: Gagal terhubung ke server";
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _fillSampleData() {
    setState(() {
      _cycleController.text = '28';
      _stressController.text = '5';
      _sleepController.text = '7';
      _healthController.text = '8';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data contoh telah diisi'),
        backgroundColor: Colors.pink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _cycleController.clear();
      _stressController.clear();
      _sleepController.clear();
      _healthController.clear();
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
            onPressed: () {
              _showHistoryDialog();
            },
            tooltip: 'Riwayat Prediksi',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
            tooltip: 'Informasi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan ilustrasi
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
                    color: Colors.pink.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(0.2),
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
                    'Masukkan data untuk mendapatkan prediksi',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Data Siklus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cycle Length
                  _buildInputField(
                    controller: _cycleController,
                    label: 'Cycle Length',
                    hint: 'Panjang siklus (hari)',
                    icon: Icons.timeline,
                    tooltip: 'Rata-rata panjang siklus haid kamu',
                    unit: 'hari',
                  ),

                  const SizedBox(height: 15),

                  // Stress Level
                  _buildInputField(
                    controller: _stressController,
                    label: 'Stress Level',
                    hint: '1-10',
                    icon: Icons.bolt,
                    tooltip: 'Tingkat stres (1 = rendah, 10 = tinggi)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: 15),

                  // Sleep Hours
                  _buildInputField(
                    controller: _sleepController,
                    label: 'Sleep Hours',
                    hint: 'Jam tidur',
                    icon: Icons.nightlight_round,
                    tooltip: 'Rata-rata jam tidur per hari',
                    unit: 'jam',
                  ),

                  const SizedBox(height: 15),

                  // Health Score
                  _buildInputField(
                    controller: _healthController,
                    label: 'Health Score',
                    hint: '1-10',
                    icon: Icons.favorite,
                    tooltip: 'Skor kesehatan umum',
                    unit: 'skala',
                  ),

                  const SizedBox(height: 15),

                  // Last Period Date
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Colors.pink.shade300),
                      title: const Text('Tanggal Haid Terakhir'),
                      subtitle: Text(_dateController.text),
                      trailing: const Icon(Icons.edit, color: Colors.pink),
                      onTap: _selectDate,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Action Buttons
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Helper buttons
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

            // Result Card
            if (_result.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.shade400,
                      Colors.pink.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '✨ Hasil Prediksi ✨',
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: _result.split('\n').map((line) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  line.startsWith('Siklus') 
                                      ? Icons.timeline 
                                      : Icons.calendar_today,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
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
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Prediksi berdasarkan data yang dimasukkan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tips Section
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTipItem(
                    'Catat siklus minimal 3 bulan untuk prediksi lebih akurat',
                  ),
                  _buildTipItem(
                    'Semakin lengkap data (stres, tidur, kesehatan) semakin baik',
                  ),
                  _buildTipItem(
                    'Gunakan tanggal haid terakhir yang valid',
                  ),
                  _buildTipItem(
                    'Konsisten dalam mencatat gejala dan mood',
                  ),
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
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: tooltip,
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey.shade400,
              ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
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
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
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
            const Center(
              child: Text(
                'Riwayat Prediksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._recentPredictions.map((pred) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haid: ${pred['date']}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Siklus ${pred['cycle']} hari → ${pred['next']}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pred['accuracy'] == 'Tepat'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pred['accuracy'],
                      style: TextStyle(
                        color: pred['accuracy'] == 'Tepat'
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
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
              'Prediksi dihitung berdasarkan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildInfoBullet('Panjang siklus rata-rata'),
            _buildInfoBullet('Tingkat stres (mempengaruhi hormon)'),
            _buildInfoBullet('Pola tidur (mempengaruhi siklus)'),
            _buildInfoBullet('Skor kesehatan umum'),
            _buildInfoBullet('Tanggal haid terakhir'),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Semakin lengkap data yang dimasukkan, semakin akurat hasil prediksi.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.pink,
                ),
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
          Text(text),
        ],
      ),
    );
  }
}