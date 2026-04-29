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

  final _lastPeriodController = TextEditingController();
  final _previousPeriodController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _periodDurationController = TextEditingController();

  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  bool _isLoading = false;

  String? _savedCycleMongoId;

  @override
  void initState() {
    super.initState();
    _cycleLengthController.text = '28';
    _periodDurationController.text = '5';
  }

  @override
  void dispose() {
    _lastPeriodController.dispose();
    _previousPeriodController.dispose();
    _cycleLengthController.dispose();
    _periodDurationController.dispose();
    super.dispose();
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

      if (_lastPeriodDate != null && _previousPeriodDate != null) {
        _calculateCycleLength();
      }

      setState(() {});
    }
  }

  void _calculateCycleLength() {
    if (_lastPeriodDate != null && _previousPeriodDate != null) {
      final difference = _lastPeriodDate!
          .difference(_previousPeriodDate!)
          .inDays;
      if (difference > 0) {
        setState(() {
          _cycleLengthController.text = difference.abs().toString();
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();

      if (user == null || user.idUser == null) {
        throw Exception('User tidak ditemukan. Silakan login kembali.');
      }

      String lastPeriodFormatted = DateFormat(
        'yyyy-MM-dd',
      ).format(_lastPeriodDate!);
      String? previousPeriodFormatted = _previousPeriodDate != null
          ? DateFormat('yyyy-MM-dd').format(_previousPeriodDate!)
          : null;

      final result = await CycleService.saveMandatoryData(
        idUser: user.idUser!,
        lastPeriodDate: lastPeriodFormatted,
        previousPeriodDate: previousPeriodFormatted,
        cycleLengthDays: int.parse(_cycleLengthController.text),
        periodDurationDays: int.parse(_periodDurationController.text),
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
              // Perbaiki ini: jangan pakai named route
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
                      cycleLengthDays: int.parse(_cycleLengthController.text),
                      periodDurationDays: int.parse(
                        _periodDurationController.text,
                      ),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
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

  void _saveCycleIdToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_savedCycleMongoId != null) {
      await prefs.setString('latest_cycle_id', _savedCycleMongoId!);
    }
  }

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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.pink.shade200),
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

                TextFormField(
                  controller: _lastPeriodController,
                  readOnly: true,
                  onTap: () =>
                      _selectDate(context, _lastPeriodController, (date) {
                        _lastPeriodDate = date;
                      }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Terakhir',
                    hintText: 'Pilih tanggal',
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: Colors.pink.shade300,
                    ),
                    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Tanggal haid terakhir wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _previousPeriodController,
                  readOnly: true,
                  onTap: () =>
                      _selectDate(context, _previousPeriodController, (date) {
                        _previousPeriodDate = date;
                      }),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Haid Sebelumnya',
                    hintText: 'Pilih tanggal (opsional)',
                    prefixIcon: Icon(
                      Icons.calendar_month,
                      color: Colors.pink.shade300,
                    ),
                    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.pink),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    helperText: 'Kosongkan jika tidak tahu',
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panjang Siklus',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_lastPeriodDate != null &&
                          _previousPeriodDate != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Siklus terhitung: ${_cycleLengthController.text} hari',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cycleLengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Atau masukkan manual',
                          hintText: 'Contoh: 28',
                          suffixText: 'hari',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Panjang siklus wajib diisi';
                          if (int.tryParse(value) == null)
                            return 'Masukkan angka yang valid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _periodDurationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Lama Haid (hari)',
                    hintText: 'Contoh: 5',
                    prefixIcon: Icon(Icons.timer, color: Colors.pink.shade300),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Lama haid wajib diisi';
                    final days = int.tryParse(value);
                    if (days == null) return 'Masukkan angka yang valid';
                    if (days < 2 || days > 10)
                      return 'Lama haid normal 2-10 hari';
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data ini akan digunakan untuk prediksi siklus haid kamu. '
                          'Semakin lengkap datanya, semakin akurat prediksinya.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan & Lanjutkan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
