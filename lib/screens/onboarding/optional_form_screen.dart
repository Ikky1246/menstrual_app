// lib/screens/onboarding/optional_form_screen.dart
// VERSION FINAL - Sesuai dengan API Laravel

import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/services/cycle_service.dart';
import 'package:menstrual_app/utils/constants.dart';

class OptionalFormScreen extends StatefulWidget {
  final String cycleId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int cycleLengthDays;
  final int periodDurationDays;
  
  // Data dari Mandatory Form
  final int painLevel;
  final int stressLevel;
  final double sleepHours;
  final int moodLevel;

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
  
  // Data dari mandatory (tidak perlu diisi ulang)
  late int _stressLevel;
  late double _sleepHours;
  late int _moodLevel;
  
  // Data opsional tambahan
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

  print('📝 _saveAndContinue() di OptionalFormScreen');
  print('   cycleId: ${widget.cycleId}');
  print('   painLevel: ${widget.painLevel}');
  print('   stressLevel: $_stressLevel');
  print('   sleepHours: $_sleepHours');
  print('   moodLevel: $_moodLevel');

  // ✅ UPDATE: Gunakan updateCycle dengan parameter yang benar
  final result = await CycleService.updateCycle(
    cycleId: widget.cycleId,
    painLevel: widget.painLevel,
    stressScoreCycle: _stressLevel,
    sleepHoursCycle: _sleepHours,
    moodScore: _moodLevel,
  );

  print('📊 Update result: ${result['success']}');
  print('   Message: ${result['message']}');

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
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan data'),
          backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.primary,
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
            colors: [AppColors.primaryLight, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info - Data sudah diisi dari mandatory
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Dasar Sudah Tersimpan',
                            style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                          Text(
                            'Nyeri: ${widget.painLevel}/10 | Stres: $_stressLevel/10 | Tidur: ${_sleepHours.toStringAsFixed(1)} jam',
                            style: TextStyle(fontSize: AppFontSize.sm, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // ============================================
              // SECTION: DATA YANG SUDAH DIISI (READ ONLY)
              // ============================================
              
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Ringkasan Data Anda',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppFontSize.md, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildInfoChip(Icons.favorite, 'Nyeri: ${widget.painLevel}/10', AppColors.primary),
                        _buildInfoChip(Icons.bolt, 'Stres: $_stressLevel/10', Colors.orange),
                        _buildInfoChip(Icons.nightlight_round, 'Tidur: ${_sleepHours.toStringAsFixed(1)} jam', Colors.indigo),
                        _buildInfoChip(Icons.mood, 'Mood: ${_getMoodLabel(_moodLevel)}', AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // ============================================
              // SECTION: DATA TAMBAHAN OPSIONAL
              // ============================================
              
              const Text('📝 Data Tambahan (Opsional)', 
                  style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text('Isi untuk mendapatkan prediksi yang lebih akurat',
                  style: TextStyle(fontSize: AppFontSize.sm, color: Colors.grey)),
              const SizedBox(height: AppSpacing.md),
              
              // Mood (sudah terisi, bisa diubah)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mood, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          const Text('Mood Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
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
                            selectedColor: AppColors.primaryLight,
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // ============================================
              // GEJALA (Optional - tidak dipakai model)
              // ============================================
              
              const Text('🤕 Gejala yang Dirasakan', 
                  style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
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
                        color: symptom['selected'] ? AppColors.primaryLight : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        border: Border.all(
                          color: symptom['selected'] ? AppColors.primary : Colors.grey.shade300,
                          width: symptom['selected'] ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(symptom['icon'] as IconData, 
                              color: symptom['selected'] ? AppColors.primary : Colors.grey.shade600,
                              size: 28),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            symptom['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: symptom['selected'] ? AppColors.primary : Colors.grey.shade700,
                              fontWeight: symptom['selected'] ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // ============================================
              // BERAT BADAN & TINGGI (Opsional - untuk BMI)
              // ============================================
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: Colors.teal),
                          const SizedBox(width: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Berat Badan (kg)',
                                  hintText: 'Contoh: 55',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) {
                                  _weight = double.tryParse(value) ?? 0;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Tinggi Badan (cm)',
                                  hintText: 'Contoh: 165',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                                  filled: true,
                                  fillColor: Colors.white,
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
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'BMI: ${(_weight / ((_height / 100) * (_height / 100))).toStringAsFixed(1)}',
                              style: TextStyle(fontSize: AppFontSize.sm, color: Colors.teal),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Catatan
              const Text('📝 Catatan Tambahan', 
                  style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Hari ini merasa sangat lelah...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                  filled: true,
                  fillColor: Colors.white,
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
                      : const Text('Selesai & Lihat Dashboard', 
                          style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(fontSize: AppFontSize.sm, color: color)),
        ],
      ),
    );
  }
}