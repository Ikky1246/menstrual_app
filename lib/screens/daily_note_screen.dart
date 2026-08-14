// lib/screens/daily_note_screen.dart
// REDESIGNED UI - Mengikuti desain MIRAI Catatan Harian dari HTML
// Logika tetap sama, hanya tampilan yang diubah

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/daily_note_service.dart';

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

  final Color primary = const Color(0xFFEC1E63);
  final Color primaryLight = const Color(0xFFFFD3E0);
  final Color surface = const Color(0xFFFFF8F7);
  final Color onSurface = const Color(0xFF281719);
  final Color onSurfaceVariant = const Color(0xFF5C3F43);

  final List<Map<String, dynamic>> _symptoms = [
    {'name': 'Kram perut', 'selected': false},
    {'name': 'Sakit kepala', 'selected': false},
    {'name': 'Lelah', 'selected': false},
    {'name': 'Kembung', 'selected': false},
    {'name': 'Payudara nyeri', 'selected': false},
    {'name': 'Jerawat', 'selected': false},
    {'name': 'Mood swing', 'selected': false},
    {'name': 'Sakit punggung', 'selected': false},
    {'name': 'Mual', 'selected': false},
    {'name': 'Insomnia', 'selected': false},
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
    setState(() => _isLoading = true);
    try {
      final result = await DailyNoteService.getNoteByDate(_selectedDate);
      if (result['success'] == true && result['note'] != null) {
        final note = result['note'];
        setState(() {
          _moodLevel = note.moodLevel ?? 5;
          _notesController.text = note.notes ?? '';
          for (var symptom in _symptoms) {
            symptom['selected'] =
                note.symptoms?.contains(symptom['name']) ?? false;
          }
        });
      }
    } catch (e) {
      print('Error loading note: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadExistingNote();
    }
  }

  Future<void> _saveNote() async {
    if (_notesController.text.trim().isEmpty &&
        !_symptoms.any((s) => s['selected'] == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi catatan atau pilih gejala')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final selectedSymptoms = _symptoms
        .where((s) => s['selected'] == true)
        .map((s) => s['name'] as String)
        .toList();

    try {
      final result = await DailyNoteService.saveNote(
        date: _selectedDate,
        moodLevel: _moodLevel,
        symptoms: selectedSymptoms,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil disimpan ✅'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan catatan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Save Note Error: $e');
      if (mounted) {
        String errorMsg = 'Gagal menyimpan catatan';
        if (e.toString().contains('HTML') || e.toString().contains('login')) {
          errorMsg = 'Anda belum login. Silakan login terlebih dahulu.';
        } else if (e.toString().contains('Socket') ||
            e.toString().contains('Connection')) {
          errorMsg = 'Tidak dapat terhubung ke server';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getMoodEmoji(int value) {
    if (value <= 2) return '😢';
    if (value <= 4) return '☹️';
    if (value <= 6) return '😐';
    if (value <= 8) return '🙂';
    return '😊';
  }

  String _getMoodLabel(int value) {
    if (value <= 2) return 'Sangat buruk';
    if (value <= 4) return 'Buruk';
    if (value <= 6) return 'Biasa';
    if (value <= 8) return 'Baik';
    return 'Luar biasa';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryLight.withOpacity(0.6),
              surface.withOpacity(0.3),
              primaryLight.withOpacity(0.4),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Sakura Petals Background Decorations
            ..._buildSakuraDecorations(),

            // Main Content
            Column(
              children: [
                // ===== GLASS TOP APP BAR =====
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        'Catatan Harian',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const Spacer(),
                      // Calendar Button
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== BODY CONTENT =====
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFEC1E63),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Selector
                              _buildGlassCard(
                                child: Center(
                                  child: Text(
                                    DateFormat(
                                      'EEEE, dd MMMM yyyy',
                                      'id',
                                    ).format(_selectedDate),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Mood Section
                              Row(
                                children: [
                                  const Text(
                                    '😊',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bagaimana perasaanmu hari ini?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildGlassCard(
                                child: Column(
                                  children: [
                                    // Slider
                                    Slider(
                                      value: _moodLevel.toDouble(),
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      activeColor: primary,
                                      inactiveColor: primaryLight,
                                      thumbColor: Colors.white,
                                      overlayColor: WidgetStateProperty.all(
                                        primary.withOpacity(0.2),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _moodLevel = value.toInt(),
                                      ),
                                    ),

                                    // Labels
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Sangat buruk',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: onSurfaceVariant,
                                              fontFamily: 'PlusJakartaSans',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Text(
                                            'Luar biasa',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: onSurfaceVariant,
                                              fontFamily: 'PlusJakartaSans',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Mood Display
                                    Column(
                                      children: [
                                        Text(
                                          _getMoodLabel(_moodLevel),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: primary,
                                            fontFamily: 'PlusJakartaSans',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getMoodEmoji(_moodLevel),
                                          style: const TextStyle(fontSize: 48),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Symptoms Section
                              Row(
                                children: [
                                  const Text(
                                    '🤕',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Gejala yang dirasakan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildGlassCard(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _symptoms.map((symptom) {
                                    final isSelected =
                                        symptom['selected'] as bool;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        symptom['selected'] = !isSelected;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primary
                                              : Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? primary
                                                : primary.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: primary.withOpacity(
                                                      0.3,
                                                    ),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          symptom['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? Colors.white
                                                : onSurface,
                                            fontFamily: 'PlusJakartaSans',
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Notes Section
                              Row(
                                children: [
                                  const Text(
                                    '📝',
                                    style: TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Catatan tambahan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              _buildGlassCard(
                                child: TextField(
                                  controller: _notesController,
                                  maxLines: 6,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis catatanmu di sini...',
                                    hintStyle: TextStyle(
                                      color: onSurfaceVariant.withOpacity(0.7),
                                      fontFamily: 'PlusJakartaSans',
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: onSurface,
                                    fontFamily: 'PlusJakartaSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),

            // ===== FIXED BOTTOM SAVE BUTTON =====
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 8,
                        shadowColor: primary.withOpacity(0.3),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'SIMPAN CATATAN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                fontFamily: 'PlusJakartaSans',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== GLASS CARD HELPER =====
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  // ===== SAKURA DECORATIONS =====
  List<Widget> _buildSakuraDecorations() {
    return [
      // Petal 1
      Positioned(
        top: 100,
        left: -20,
        child: Transform.rotate(
          angle: 0.8,
          child: Icon(
            Icons.favorite,
            color: primaryLight.withOpacity(0.3),
            size: 120,
          ),
        ),
      ),
      // Petal 2
      Positioned(
        bottom: 200,
        right: -30,
        child: Transform.rotate(
          angle: -0.5,
          child: Icon(
            Icons.favorite,
            color: primaryLight.withOpacity(0.25),
            size: 100,
          ),
        ),
      ),
      // Petal 3 - small
      Positioned(
        top: 300,
        right: 20,
        child: Transform.rotate(
          angle: 0.3,
          child: Icon(
            Icons.favorite,
            color: primaryLight.withOpacity(0.2),
            size: 60,
          ),
        ),
      ),
      // Blur Circle 1
      Positioned(
        top: 80,
        left: -40,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(150),
          ),
        ),
      ),
      // Blur Circle 2
      Positioned(
        bottom: 150,
        right: -40,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(120),
          ),
        ),
      ),
    ];
  }
}
