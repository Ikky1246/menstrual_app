// lib/screens/daily_note_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/daily_note_service.dart';
import 'mirai_chat_screen.dart'; // ← Import Chat
import 'profile_screen.dart'; // ← Import Profile (jika sudah ada)

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

  // Bottom Navigation State
  int _currentIndex = 1; // 1 = Catatan (karena ini halaman Catatan)

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
      backgroundColor: const Color(0xFFF8E8F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Catatan Harian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),

      // Body tetap sama persis
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat(
                        'EEEE, dd MMMM yyyy',
                        'id',
                      ).format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Mood Section
                  const Text(
                    '😊 Bagaimana perasaanmu hari ini?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Slider(
                          value: _moodLevel.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          activeColor: Colors.pink,
                          inactiveColor: Colors.pink.shade100,
                          onChanged: (value) =>
                              setState(() => _moodLevel = value.toInt()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Sangat buruk',
                              style: TextStyle(fontSize: 13),
                            ),
                            Text('Luar biasa', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getMoodLabel(_moodLevel),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        Text(
                          _getMoodEmoji(_moodLevel),
                          style: const TextStyle(fontSize: 48),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Symptoms
                  const Text(
                    '🤕 Gejala yang dirasakan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _symptoms.map((symptom) {
                        final isSelected = symptom['selected'] as bool;
                        return FilterChip(
                          label: Text(symptom['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => symptom['selected'] = selected);
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.pink.shade50,
                          checkmarkColor: Colors.pink,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.pink : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    '📝 Catatan tambahan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatanmu di sini...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveNote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SIMPAN CATATAN',
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

      // ==================== BOTTOM NAVIGATION BAR ====================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MiraiChatScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            activeIcon: Icon(Icons.description),
            label: "Catatan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}
