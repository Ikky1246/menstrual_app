// lib/screens/prediction_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart'; // Pastikan ini ada
// Import custom theme kalau ada
// import '../utils/app_colors.dart';   // Uncomment jika ada

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _dateController = TextEditingController();
  final _previousDateController = TextEditingController();
  final _painController = TextEditingController();
  final _stressController = TextEditingController();
  final _sleepController = TextEditingController();
  final _moodController = TextEditingController();

  String _result = "";
  bool _isLoading = false;
  DateTime? _selectedDate;
  DateTime? _selectedPreviousDate;
  bool _showTips = true;
  List<Map<String, dynamic>> _recentPredictions = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);

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
    );
    if (picked != null) {
      setState(() {
        _selectedPreviousDate = picked;
        _previousDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _predict() async {
    if (_dateController.text.isEmpty) {
      _showError('Tanggal haid terakhir harus diisi!');
      return;
    }

    int painLevel = int.tryParse(_painController.text) ?? 0;
    int stressLevel = int.tryParse(_stressController.text) ?? 0;
    double sleepHours = double.tryParse(_sleepController.text) ?? 7;
    int? moodScore = _moodController.text.isNotEmpty
        ? int.tryParse(_moodController.text)
        : null;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.predictCycle(
        tanggalHaidTerakhir: _dateController.text,
        tanggalHaidBulanSebelumnya: _previousDateController.text.isNotEmpty
            ? _previousDateController.text
            : null,
        painLevel: painLevel,
        stressScore: stressLevel,
        sleepHours: sleepHours,
        moodScore: moodScore,
      );

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _result =
              "📊 Prediksi Panjang Siklus: ${data['predicted_cycle_length']} hari\n"
              "📅 Perkiraan Haid Berikutnya: ${data['next_period_date']}\n"
              "🎯 Tingkat Kepercayaan: ${data['confidence_level']}\n"
              "📏 Margin Error: ±${data['error_margin']} hari";
        });
        _showSuccess('Prediksi berhasil!');
        _loadPredictionHistory();
      } else {
        _showError(result['message'] ?? 'Gagal mendapatkan prediksi');
      }
    } catch (e) {
      print('Prediction error: $e');
      _showError('Gagal terhubung ke server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _fillSampleData() {
    setState(() {
      DateTime sampleDate = DateTime.now().subtract(const Duration(days: 28));
      _selectedDate = sampleDate;
      _dateController.text = DateFormat('yyyy-MM-dd').format(sampleDate);
      _painController.text = '5';
      _stressController.text = '4';
      _sleepController.text = '7';
      _moodController.text = '7';
    });
    _showSuccess('Data contoh telah diisi');
  }

  void _clearForm() {
    setState(() {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _previousDateController.clear();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Prediksi Haid'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () {}),
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Form (kode kamu tetap sama, saya tidak ubah logika)
            // ... (lanjutkan kode build kamu yang lama di sini)
            // Saya hanya memperbaiki struktur dan error yang ada
          ],
        ),
      ),
    );
  }
}
