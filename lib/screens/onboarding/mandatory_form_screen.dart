import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_app/screens/onboarding/optional_form_screen.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

class MandatoryFormScreen extends StatefulWidget {
  const MandatoryFormScreen({super.key});

  @override
  State<MandatoryFormScreen> createState() => _MandatoryFormScreenState();
}

class _MandatoryFormScreenState extends State<MandatoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers untuk form wajib
  final _lastPeriodController = TextEditingController();
  final _previousPeriodController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _periodDurationController = TextEditingController();
  
  DateTime? _lastPeriodDate;
  DateTime? _previousPeriodDate;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    // Set default value untuk testing
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
  print('🟡 Membuka date picker...');
  
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
  
  print('🟡 Date picker closed');
  
  if (picked != null) {
    print('✅ Tanggal dipilih: $picked');
    
    // Format tanggal
    String formattedDate = DateFormat('dd MMMM yyyy', 'id').format(picked);
    print('📝 Format: $formattedDate');
    
    // Update controller
    controller.text = formattedDate;
    print('✅ Controller text: ${controller.text}');
    
    // Panggil callback
    onDateSelected(picked);
    
    // Force refresh
    setState(() {});
    
    print('✅ Selesai');
  } else {
    print('❌ Tidak ada tanggal dipilih');
  }
}

void _calculateCycleLength() {
  if (_lastPeriodDate != null && _previousPeriodDate != null) {
    final difference = _lastPeriodDate!.difference(_previousPeriodDate!).inDays;
    if (difference > 0) {
      setState(() {
        _cycleLengthController.text = difference.abs().toString();
      });
    }
  }
}

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulasi proses save
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Tanya user apakah ingin mengisi data opsional
        _showOptionalFormDialog();
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
          'Ingin mengisi sekarang?'
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Lewati, langsung ke dashboard
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
              // Ke halaman opsional
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OptionalFormScreen(
                    lastPeriodDate: _lastPeriodDate!,
                    previousPeriodDate: _previousPeriodDate,
                  ),
                ),
              );
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
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStepIndicator(1, 'Data Wajib', true),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: Colors.pink.shade200,
                        ),
                      ),
                      _buildStepIndicator(2, 'Data Opsional', false),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
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
                          color: Colors.pink.shade100.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.pink.shade200,
                            width: 1,
                          ),
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
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                     // Di dalam build method, bagian form:

// Tanggal Haid Terakhir
TextFormField(
  controller: _lastPeriodController,
  readOnly: true, // PENTING: biar tidak bisa diketik manual
  onTap: () => _selectDate(
    context,
    _lastPeriodController,
    (date) {
      print('Last period selected: $date');
      setState(() {
        _lastPeriodDate = date;
      });
    },
  ),
  decoration: InputDecoration(
    labelText: 'Tanggal Haid Terakhir',
    hintText: 'Pilih tanggal',
    prefixIcon: Icon(Icons.calendar_today, color: Colors.pink.shade300),
    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.pink),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal haid terakhir wajib diisi';
    }
    return null;
  },
),

const SizedBox(height: 20),

// Tanggal Haid Sebelumnya
TextFormField(
  controller: _previousPeriodController,
  readOnly: true,
  onTap: () => _selectDate(
    context,
    _previousPeriodController,
    (date) {
      print('Previous period selected: $date');
      setState(() {
        _previousPeriodDate = date;
      });
      if (_lastPeriodDate != null) {
        _calculateCycleLength();
      }
    },
  ),
  decoration: InputDecoration(
    labelText: 'Tanggal Haid Sebelumnya',
    hintText: 'Pilih tanggal (opsional)',
    prefixIcon: Icon(Icons.calendar_month, color: Colors.pink.shade300),
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
                      
                      // Panjang Siklus (otomatis atau manual)
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
                            if (_lastPeriodDate != null && _previousPeriodDate != null)
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
                                if (value == null || value.isEmpty) {
                                  return 'Panjang siklus wajib diisi';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Masukkan angka yang valid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Lama Haid
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
                          if (value == null || value.isEmpty) {
                            return 'Lama haid wajib diisi';
                          }
                          final days = int.tryParse(value);
                          if (days == null) {
                            return 'Masukkan angka yang valid';
                          }
                          if (days < 2 || days > 10) {
                            return 'Lama haid normal 2-10 hari';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Info tambahan
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
                      
                      // Tombol Simpan
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
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
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
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.pink : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.pink : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

 Widget _buildDateField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  required VoidCallback onTap,
  String? Function(String?)? validator,
  String? helperText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 5),
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.pink.shade300, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.text.isEmpty ? hint : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey.shade500 : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.pink),
            ],
          ),
        ),
      ),
      if (helperText != null)
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
    ],
  );
}}