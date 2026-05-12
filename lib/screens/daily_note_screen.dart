// lib/screens/daily_note_screen.dart
// Halaman catatan harian (mood, gejala, catatan)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/daily_note_service.dart';
import '../utils/constants.dart';

class DailyNoteScreen extends StatefulWidget {
  final DateTime? initialDate;

  const DailyNoteScreen({super.key, this.initialDate});

  @override
  State<DailyNoteScreen> createState() => _DailyNoteScreenState();
}

class _DailyNoteScreenState extends State<DailyNoteScreen> {
  late DateTime _selectedDate;
  late TextEditingController _notesController;
  int _moodLevel = 5;
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Gejala yang umum
  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Kram perut', 'icon': Icons.crisis_alert, 'selected': false},
    {'name': 'Sakit kepala', 'icon': Icons.sick, 'selected': false},
    {'name': 'Lelah', 'icon': Icons.battery_alert, 'selected': false},
    {'name': 'Kembung', 'icon': Icons.air, 'selected': false},
    {'name': 'Payudara nyeri', 'icon': Icons.favorite, 'selected': false},
    {'name': 'Jerawat', 'icon': Icons.face, 'selected': false},
    {'name': 'Mood swing', 'icon': Icons.mood_bad, 'selected': false},
    {'name': 'Sakit punggung', 'icon': Icons.back_hand, 'selected': false},
    {'name': 'Mual', 'icon': Icons.sick, 'selected': false},
    {'name': 'Insomnia', 'icon': Icons.nightlight_round, 'selected': false},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _notesController = TextEditingController();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await DailyNoteService.getNoteByDate(_selectedDate);
      if (result['success'] == true && result['note'] != null) {
        final note = result['note'];
        setState(() {
          _moodLevel = note.moodLevel;
          _notesController.text = note.notes;
          
          // Update gejala yang dipilih
          for (var symptom in _symptoms) {
            symptom['selected'] = note.symptoms.contains(symptom['name']);
          }
        });
      }
    } catch (e) {
      print('Error loading note: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingNote();
    }
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    final selectedSymptoms = _symptoms
        .where((s) => s['selected'] == true)
        .map((s) => s['name'] as String)
        .toList();

    final result = await DailyNoteService.saveNote(
      date: _selectedDate,
      moodLevel: _moodLevel,
      symptoms: selectedSymptoms,
      notes: _notesController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil disimpan 📝'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan catatan'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getMoodLabel(int value) {
    if (value <= 2) return 'Sangat buruk 😢';
    if (value <= 4) return 'Buruk ☹️';
    if (value <= 6) return 'Biasa 😐';
    if (value <= 8) return 'Baik 🙂';
    return 'Sangat baik 😊';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catatan Harian'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Pilih Tanggal',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Tanggal
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: AppFontSize.md,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Mood Section
                  const Text(
                    '😊 Bagaimana perasaanmu hari ini?',
                    style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sangat buruk', style: TextStyle(fontSize: AppFontSize.sm)),
                              const Text('Luar biasa', style: TextStyle(fontSize: AppFontSize.sm)),
                            ],
                          ),
                          Slider(
                            value: _moodLevel.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _moodLevel = value.toInt();
                              });
                            },
                          ),
                          Align(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(AppSpacing.lg),
                              ),
                              child: Text(
                                _getMoodLabel(_moodLevel),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Symptoms Section
                  const Text(
                    '🤕 Gejala yang dirasakan',
                    style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _symptoms.map((symptom) {
                          return FilterChip(
                            label: Text(symptom['name']),
                            selected: symptom['selected'],
                            onSelected: (selected) {
                              setState(() {
                                symptom['selected'] = selected;
                              });
                            },
                            selectedColor: AppColors.primaryLight,
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Notes Section
                  const Text(
                    '📝 Catatan tambahan',
                    style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tulis catatanmu di sini...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Simpan Catatan',
                              style: TextStyle(fontSize: AppFontSize.md, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}