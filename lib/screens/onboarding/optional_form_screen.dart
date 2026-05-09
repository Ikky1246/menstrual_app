// lib/screens/onboarding/optional_form_screen.dart
// VERSION UPDATE - Fix overflow & token issue

import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/services/cycle_service.dart';

class OptionalFormScreen extends StatefulWidget {
  final String cycleId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int cycleLengthDays;
  final int periodDurationDays;
  
  // ✅ DATA BARU dari Mandatory Form (dikirim ke sini)
  final int painLevel;      // Dari mandatory (0-10)
  final int stressLevel;    // Dari mandatory (0-10)
  final double sleepHours;  // Dari mandatory (0-24)
  final int moodLevel;      // Dari mandatory (1-10)

  const OptionalFormScreen({
    super.key,
    required this.cycleId,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    required this.cycleLengthDays,
    required this.periodDurationDays,
    required this.painLevel,
    required this.stressLevel,
    required this.sleepHours,
    required this.moodLevel,
  });

  @override
  State<OptionalFormScreen> createState() => _OptionalFormScreenState();
}

class _OptionalFormScreenState extends State<OptionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // ============================================
  // DATA DARI MANDATORY (tidak perlu diisi ulang)
  // ============================================
  late int _stressLevel;
  late double _sleepHours;
  late int _moodLevel;
  
  // ============================================
  // DATA OPSIONAL TAMBAHAN (bisa diisi user)
  // ============================================
  double _weight = 0;
  double _height = 0;
  String? _selectedMood;
  final _notesController = TextEditingController();
  
  final List<Map<String, dynamic>> _commonSymptoms = [
    {'name': 'Kram perut', 'icon': Icons.crisis_alert, 'selected': false},
    {'name': 'Sakit kepala', 'icon': Icons.sick, 'selected': false},
    {'name': 'Lelah', 'icon': Icons.battery_alert, 'selected': false},
    {'name': 'Kembung', 'icon': Icons.air, 'selected': false},
    {'name': 'Payudara nyeri', 'icon': Icons.favorite, 'selected': false},
    {'name': 'Jerawat', 'icon': Icons.face, 'selected': false},
    {'name': 'Mood swing', 'icon': Icons.mood_bad, 'selected': false},
    {'name': 'Sakit punggung', 'icon': Icons.back_hand, 'selected': false},
  ];
  
  final List<String> _moods = ['😊 Baik', '😐 Biasa', '😢 Sedih', '😠 Mudah marah', '😴 Lelah'];
  
  bool _isLoading = false;
  bool _showWeightHeight = false;

  @override
  void initState() {
    super.initState();
    _stressLevel = widget.stressLevel;
    _sleepHours = widget.sleepHours;
    _moodLevel = widget.moodLevel;
    
    // Konversi mood level ke emoji
    if (_moodLevel >= 8) {
      _selectedMood = '😊 Baik';
    } else if (_moodLevel >= 6) {
      _selectedMood = '😐 Biasa';
    } else if (_moodLevel >= 4) {
      _selectedMood = '😢 Sedih';
    } else {
      _selectedMood = '😠 Mudah marah';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    final symptomsList = _commonSymptoms
        .where((s) => s['selected'] == true)
        .map((s) => s['name'] as String)
        .toList();
    
    // Gabungkan mood dengan catatan
    String fullNotes = _notesController.text;
    if (_selectedMood != null && _selectedMood!.isNotEmpty) {
      fullNotes = fullNotes.isEmpty 
          ? 'Mood: $_selectedMood' 
          : '$_selectedMood\n${_notesController.text}';
    }

    final result = await CycleService.updateOptionalData(
      cycleId: widget.cycleId,
      painLevel: widget.painLevel,
      stressScoreCycle: _stressLevel,
      sleepHoursCycle: _sleepHours,
      moodLevel: _moodLevel,
      weight: _weight > 0 ? _weight : null,
      height: _height > 0 ? _height : null,
      symptoms: symptomsList.isNotEmpty ? symptomsList : null,
      notes: fullNotes.isNotEmpty ? fullNotes : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil disimpan! Selamat datang 🎉'),
              backgroundColor: Colors.pink,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getMoodEmoji(int level) {
    if (level >= 8) return '😊';
    if (level >= 6) return '🙂';
    if (level >= 4) return '😐';
    if (level >= 2) return '😢';
    return '😠';
  }
  
  String _getMoodLabel(int level) {
    if (level >= 8) return 'Sangat Baik';
    if (level >= 6) return 'Baik';
    if (level >= 4) return 'Biasa';
    if (level >= 2) return 'Sedih';
    return 'Sangat Buruk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Tambahan'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
            child: const Text('Lewati', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info - Data sudah diisi dari mandatory
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Dasar Sudah Tersimpan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text(
                            'Tingkat nyeri: ${widget.painLevel}/10 | Stres: $_stressLevel/10 | Tidur: ${_sleepHours.toStringAsFixed(1)} jam',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ============================================
              // SECTION: DATA YANG SUDAH DIISI (READ ONLY)
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
                    const Text(
                      '📋 Ringkasan Data Anda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    // FIX OVERFLOW: Gunakan Wrap agar bisa pindah baris
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.favorite, 'Nyeri: ${widget.painLevel}/10', Colors.red),
                        _buildInfoChip(Icons.bolt, 'Stres: $_stressLevel/10', Colors.orange),
                        _buildInfoChip(Icons.nightlight_round, 'Tidur: ${_sleepHours.toStringAsFixed(1)} jam', Colors.indigo),
                        _buildInfoChip(Icons.mood, 'Mood: ${_getMoodLabel(_moodLevel)}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // ============================================
              // SECTION: DATA TAMBAHAN OPSIONAL
              // ============================================
              
              const Text('📝 Data Tambahan (Opsional)', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Isi untuk mendapatkan prediksi yang lebih akurat',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              
              // Mood (sudah terisi, bisa diubah)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mood, color: Colors.pink.shade400),
                          const SizedBox(width: 10),
                          const Text('Mood Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _moods.map((mood) {
                          final isSelected = _selectedMood == mood;
                          return ChoiceChip(
                            label: Text(mood),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedMood = selected ? mood : null;
                                if (mood.contains('😊')) _moodLevel = 8;
                                else if (mood.contains('😐')) _moodLevel = 6;
                                else if (mood.contains('😢')) _moodLevel = 4;
                                else if (mood.contains('😠')) _moodLevel = 2;
                                else if (mood.contains('😴')) _moodLevel = 3;
                                else _moodLevel = 5;
                              });
                            },
                            selectedColor: Colors.pink.shade100,
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // ============================================
              // GEJALA (Optional - tidak dipakai model)
              // ============================================
              
              const Text('🤕 Gejala yang Dirasakan', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // FIX: GridView dengan ukuran lebih kecil agar pas
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _commonSymptoms.length,
                itemBuilder: (context, index) {
                  final symptom = _commonSymptoms[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        symptom['selected'] = !symptom['selected'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: symptom['selected'] ? Colors.pink.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: symptom['selected'] ? Colors.pink : Colors.grey.shade300,
                          width: symptom['selected'] ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(symptom['icon'] as IconData, 
                              color: symptom['selected'] ? Colors.pink : Colors.grey.shade600,
                              size: 28),
                          const SizedBox(height: 4),
                          Text(
                            symptom['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: symptom['selected'] ? Colors.pink : Colors.grey.shade700,
                              fontWeight: symptom['selected'] ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // ============================================
              // BERAT BADAN & TINGGI (Opsional - untuk BMI)
              // ============================================
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: Colors.teal),
                          const SizedBox(width: 10),
                          const Text('Data Fisik (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showWeightHeight = !_showWeightHeight;
                              });
                            },
                            child: Text(_showWeightHeight ? 'Sembunyikan' : 'Isi'),
                          ),
                        ],
                      ),
                      if (_showWeightHeight) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Berat Badan (kg)',
                                  hintText: 'Contoh: 55',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _weight = double.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tinggi Badan (cm)',
                                  hintText: 'Contoh: 165',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  _height = double.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_weight > 0 && _height > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'BMI: ${(_weight / ((_height / 100) * (_height / 100))).toStringAsFixed(1)}',
                              style: TextStyle(fontSize: 12, color: Colors.teal),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Catatan
              const Text('📝 Catatan Tambahan', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Hari ini merasa sangat lelah...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.white,
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
                      : const Text('Selesai & Lihat Dashboard', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}