import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/services/cycle_service.dart';

class OptionalFormScreen extends StatefulWidget {
  final String cycleId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int cycleLengthDays;
  final int periodDurationDays;

  const OptionalFormScreen({
    super.key,
    required this.cycleId,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    required this.cycleLengthDays,
    required this.periodDurationDays,
  });

  @override
  State<OptionalFormScreen> createState() => _OptionalFormScreenState();
}

class _OptionalFormScreenState extends State<OptionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int _stressLevel = 5;
  double _sleepHours = 7.0;
  
  final List<Map<String, dynamic>> _commonSymptoms = [
    {'name': 'Kram perut', 'icon': Icons.crisis_alert, 'selected': false},
    {'name': 'Sakit kepala', 'icon': Icons.sick, 'selected': false},
    {'name': 'Lelah', 'icon': Icons.battery_alert, 'selected': false},
    {'name': 'Kembung', 'icon': Icons.air, 'selected': false},
    {'name': 'Payudara nyeri', 'icon': Icons.favorite, 'selected': false},
    {'name': 'Jerawat', 'icon': Icons.face, 'selected': false},
    {'name': 'Mood swing', 'icon': Icons.mood_bad, 'selected': false},
    {'name': 'Sakit punggung', 'icon': Icons.back_hand, 'selected': false},
    {'name': 'Mual', 'icon': Icons.sick, 'selected': false},
    {'name': 'Diare', 'icon': Icons.water_drop, 'selected': false},
    {'name': 'Susah tidur', 'icon': Icons.nightlight, 'selected': false},
  ];
  
  String? _selectedMood;
  final List<String> _moods = ['😊 Baik', '😐 Biasa', '😢 Sedih', '😠 Mudah marah', '😴 Lelah'];
  
  final _notesController = TextEditingController();
  bool _isLoading = false;

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
      stressScoreCycle: _stressLevel,
      sleepHoursCycle: _sleepHours,
      symptoms: symptomsList.isNotEmpty ? symptomsList : null,
      notes: fullNotes.isNotEmpty ? fullNotes : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Opsional',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                          Text('Lengkapi untuk prediksi lebih akurat', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              _buildSliderCard(
                title: 'Tingkat Stres',
                subtitle: 'Seberapa stres kamu akhir-akhir ini?',
                icon: Icons.bolt,
                color: Colors.orange,
                min: 1,
                max: 10,
                divisions: 9,
                value: _stressLevel.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _stressLevel = value.round();
                  });
                },
                displayValue: '$_stressLevel/10',
              ),
              
              const SizedBox(height: 20),
              
              _buildSliderCard(
                title: 'Rata-rata Tidur',
                subtitle: 'Berapa jam kamu tidur per hari?',
                icon: Icons.nightlight_round,
                color: Colors.indigo,
                min: 1,
                max: 12,
                divisions: 11,
                value: _sleepHours,
                onChanged: (value) {
                  setState(() {
                    _sleepHours = value;
                  });
                },
                displayValue: '${_sleepHours.toStringAsFixed(1)} jam',
              ),
              
              const SizedBox(height: 30),
              
              const Text('Gejala yang Dirasakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
                              size: 30),
                          const SizedBox(height: 5),
                          Text(
                            symptom['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
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
              
              const SizedBox(height: 30),
              
              const Text('Mood Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return ChoiceChip(
                    label: Text(mood),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMood = selected ? mood : null;
                      });
                    },
                    selectedColor: Colors.pink.shade100,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.pink : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 30),
              
              const Text('Catatan Tambahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      : const Text('Selesai & Lihat Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double min,
    required double max,
    required int divisions,
    required double value,
    required Function(double) onChanged,
    required String displayValue,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(displayValue, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}