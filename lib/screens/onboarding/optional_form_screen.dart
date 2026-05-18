// lib/screens/onboarding/optional_form_screen.dart
// VERSION FINAL - Desain sesuai HTML (tanpa perubahan logika) - Fixed

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
  
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Baik', 'level': 8},
    {'emoji': '😐', 'label': 'Biasa', 'level': 6},
    {'emoji': '😢', 'label': 'Sedih', 'level': 4},
    {'emoji': '😠', 'label': 'Mudah marah', 'level': 2},
    {'emoji': '😴', 'label': 'Lelah', 'level': 3},
  ];
  
  bool _isLoading = false;
  bool _showWeightHeight = false;

  @override
  void initState() {
    super.initState();
    _stressLevel = widget.stressLevel;
    _sleepHours = widget.sleepHours;
    _moodLevel = widget.moodLevel;
    
    // Konversi mood level ke pilihan yang sesuai
    if (_moodLevel >= 8) {
      _selectedMood = 'Baik';
    } else if (_moodLevel >= 6) {
      _selectedMood = 'Biasa';
    } else if (_moodLevel >= 4) {
      _selectedMood = 'Sedih';
    } else if (_moodLevel >= 2) {
      _selectedMood = 'Mudah marah';
    } else {
      _selectedMood = 'Lelah';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);

    final result = await CycleService.updateCycle(
      cycleId: widget.cycleId,
      painLevel: widget.painLevel,
      stressScoreCycle: _stressLevel,
      sleepHoursCycle: _sleepHours,
      moodScore: _moodLevel,
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

  String _getMoodLabel(int level) {
    if (level >= 8) return 'Baik';
    if (level >= 6) return 'Biasa';
    if (level >= 4) return 'Sedih';
    if (level >= 2) return 'Mudah marah';
    return 'Lelah';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf4fafd),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFf4fafd).withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFe91663).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFb80049)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Data Tambahan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFb80049),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Color(0xFF6b5a60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Confirmation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFe4bdc2).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFe91663).withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFb80049).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFFb80049),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Dasar Sudah Tersimpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFFb80049),
                          ),
                        ),
                        Text(
                          'Nyeri: ${widget.painLevel}/10 | Stres: $_stressLevel/10 | Tidur: ${_sleepHours.toStringAsFixed(1)} jam',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5b3f43),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Summary Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(Icons.favorite, 'Nyeri: ${widget.painLevel}/10', const Color(0xFFf4dce4), const Color(0xFF716066)),
                _buildChip(Icons.bolt, 'Stres: $_stressLevel/10', const Color(0xFFffd9de), const Color(0xFF900038)),
                _buildChip(Icons.nightlight_round, 'Tidur: ${_sleepHours.toStringAsFixed(1)} jam', const Color(0xFFe2e9ec), const Color(0xFF161d1f)),
                _buildChip(Icons.sentiment_satisfied, 'Mood: ${_getMoodLabel(_moodLevel)}', const Color(0xFFe2e9ec), const Color(0xFF161d1f)),
              ],
            ),
            const SizedBox(height: 48),

            // Data Tambahan (Opsional) Header
            Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFFb80049), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Data Tambahan (Opsional)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF161d1f),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Isi untuk mendapatkan prediksi yang lebih akurat',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5b3f43),
              ),
            ),
            const SizedBox(height: 24),

            // Mood Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFe4bdc2).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFe91663).withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mood, color: Color(0xFFb80049), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Mood Hari Ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _moods.map((mood) {
                      final isSelected = _selectedMood == mood['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = mood['label'] as String;
                            _moodLevel = mood['level'] as int;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFe2165f).withValues(alpha: 0.1)
                                : const Color(0xFFf4fafd),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFFb80049)
                                  : const Color(0xFFe4bdc2).withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.check, size: 18, color: Color(0xFFb80049)),
                                ),
                              Text(
                                '${mood['emoji']} ${mood['label']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFFb80049) : const Color(0xFF161d1f),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

 // Symptoms Section - VERSION WITH PERFECT CENTERING
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        const Icon(Icons.medical_services, color: Color(0xFFb80049), size: 20),
        const SizedBox(width: 8),
        const Text(
          'Gejala yang Dirasakan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    LayoutBuilder(
      builder: (context, constraints) {
        // Tentukan jumlah kolom berdasarkan lebar layar
        int crossAxisCount = 4;
        if (constraints.maxWidth < 400) {
          crossAxisCount = 3; // Untuk layar kecil (HP)
        } else if (constraints.maxWidth < 600) {
          crossAxisCount = 4; // Untuk layar sedang
        } else {
          crossAxisCount = 5; // Untuk layar besar
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _commonSymptoms.length,
          itemBuilder: (context, index) {
            final symptom = _commonSymptoms[index];
            final isSelected = symptom['selected'] as bool;
            return GestureDetector(
              onTap: () {
                setState(() {
                  symptom['selected'] = !isSelected;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFb80049)
                        : const Color(0xFFe4bdc2).withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFe91663).withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFFb80049),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFe2165f).withValues(alpha: 0.3)
                                  : const Color(0xFFe8eff1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                symptom['icon'] as IconData,
                                color: isSelected 
                                    ? const Color(0xFFb80049)
                                    : const Color(0xFF5b3f43),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              symptom['name'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFFb80049) : const Color(0xFF161d1f),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  ],
),
            const SizedBox(height: 24),

            // Physical Data Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _showWeightHeight = !_showWeightHeight;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFeef5f7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFe4bdc2).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Color(0xFFb80049)),
                        const SizedBox(width: 12),
                        const Text(
                          'Data Fisik (Opsional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _showWeightHeight ? Icons.expand_less : Icons.chevron_right,
                      color: const Color(0xFFb80049),
                    ),
                  ],
                ),
              ),
            ),
            
            // Weight & Height Input (Expandable)
            if (_showWeightHeight) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFe4bdc2).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Berat Badan (kg)',
                              hintText: 'Contoh: 55',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            onChanged: (value) {
                              _weight = double.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Tinggi Badan (cm)',
                              hintText: 'Contoh: 165',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'BMI: ${(_weight / ((_height / 100) * (_height / 100))).toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFb80049)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Notes Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: Color(0xFFb80049), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Catatan Tambahan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Hari ini merasa sangat lelah...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFe4bdc2).withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFe4bdc2).withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFb80049)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2165f),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 15,
                  shadowColor: const Color(0xFFe2165f).withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Selesai & Lihat Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}