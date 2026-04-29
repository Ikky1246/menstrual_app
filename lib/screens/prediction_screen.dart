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
  final _cycleController = TextEditingController();
  final _stressController = TextEditingController();
  final _sleepController = TextEditingController();
  final _dateController = TextEditingController();

  String _result = "";
  bool _isLoading = false;
  DateTime? _selectedDate;
  
  List<Map<String, dynamic>> _recentPredictions = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    _loadLatestCycleData();
  }

  @override
  void dispose() {
    _cycleController.dispose();
    _stressController.dispose();
    _sleepController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestCycleData() async {
    try {
      final result = await CycleService.getLatestCycle();
      if (result['success'] == true && result['cycle'] != null) {
        final cycle = result['cycle'];
        setState(() {
          if (cycle.cycleLengthDays != null) {
            _cycleController.text = cycle.cycleLengthDays.toString();
          }
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
    if (_cycleController.text.isEmpty ||
        _stressController.text.isEmpty ||
        _sleepController.text.isEmpty) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Panjang siklus, tingkat stres, dan jam tidur wajib diisi!'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        cycleLengthDays: int.parse(_cycleController.text),
        stressScoreCycle: int.parse(_stressController.text),
        sleepHoursCycle: double.parse(_sleepController.text),
        startDate: _dateController.text,
      );

      if (data['success'] == true) {
        final resultData = data['data'];
        setState(() {
          _result = 
              "📊 Siklus: ${resultData['predicted_cycle_length']} hari\n"
              "📅 Tanggal berikutnya: ${resultData['next_period_date']}";
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prediksi berhasil! 🎉'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() {
          _result = "Error: ${data['message']}";
          _isLoading = false;
        });
      }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _fillSampleData() {
    setState(() {
      _cycleController.text = '28';
      _stressController.text = '5';
      _sleepController.text = '7';
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
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Informasi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    'Masukkan data untuk mendapatkan prediksi',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                    '📊 Data Siklus',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _cycleController,
                    label: 'Panjang Siklus',
                    hint: 'Contoh: 28',
                    icon: Icons.timeline,
                    tooltip: 'Rata-rata panjang siklus haid kamu (21-45 hari)',
                    unit: 'hari',
                  ),

                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _stressController,
                    label: 'Tingkat Stres',
                    hint: '1-10',
                    icon: Icons.bolt,
                    tooltip: 'Tingkat stres (1 = rendah, 10 = tinggi)',
                    unit: 'skala',
                  ),

                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _sleepController,
                    label: 'Jam Tidur',
                    hint: 'Contoh: 7',
                    icon: Icons.nightlight_round,
                    tooltip: 'Rata-rata jam tidur per hari',
                    unit: 'jam',
                  ),

                  const SizedBox(height: 15),

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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: _result.split('\n').map((line) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(
                                  line.startsWith('📊') 
                                      ? Icons.timeline 
                                      : Icons.calendar_today,
                                  color: Colors.white,
                                  size: 20,
                                ),
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
                          'Prediksi berdasarkan data yang dimasukkan',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

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
                  _buildTipItem('Catat siklus minimal 3 bulan untuk prediksi lebih akurat'),
                  _buildTipItem('Semakin lengkap data (stres, tidur) semakin baik'),
                  _buildTipItem('Gunakan tanggal haid terakhir yang valid'),
                  _buildTipItem('Konsisten dalam mencatat gejala dan mood'),
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
                style: TextStyle(fontSize: 12, color: Colors.pink),
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