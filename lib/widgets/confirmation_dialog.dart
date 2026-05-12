// lib/widgets/confirmation_dialog.dart
// Popup konfirmasi untuk koreksi siklus haid

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../services/cycle_service.dart';

class ConfirmationDialog {
  // ============================================
  // KONFIRMASI AWAL HAID
  // ============================================
  static Future<void> showPeriodStartConfirmation({
    required BuildContext context,
    required DateTime expectedDate,
    required Function(DateTime) onConfirmed,
  }) async {
    DateTime selectedDate = expectedDate;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.favorite, color: AppColors.menstruation),
              const SizedBox(width: 10),
              const Text('Konfirmasi Haid'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda sudah mengalami haid?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tanggal mulai haid:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 10)),
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
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dengan mengkonfirmasi, AI akan belajar dan prediksi akan semakin akurat.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Belum', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _saveCorrectionAndNotify(context, expectedDate, selectedDate, 'start');
                onConfirmed(selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.menstruation,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sudah Haid'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // KONFIRMASI SELESAI HAID
  // ============================================
  static Future<void> showPeriodEndConfirmation({
    required BuildContext context,
    required DateTime expectedEndDate,
    required DateTime startDate,
    required Function(DateTime) onConfirmed,
  }) async {
    DateTime selectedDate = expectedEndDate;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.favorite, color: AppColors.menstruation),
              const SizedBox(width: 10),
              const Text('Konfirmasi Selesai Haid'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah haid Anda sudah selesai?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tanggal selesai haid:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: startDate,
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
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dengan mengkonfirmasi, AI akan belajar dan prediksi akan semakin akurat.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Belum', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // expectedEndDate di sini diperkirakan 7 hari setelah startDate
                final expectedEnd = startDate.add(const Duration(days: 7));
                await _saveCorrectionAndNotify(context, expectedEnd, selectedDate, 'end');
                onConfirmed(selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Selesai Haid'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SIMPAN KOREKSI DAN NOTIFIKASI
  // ============================================
  static Future<void> _saveCorrectionAndNotify(
    BuildContext context,
    DateTime expectedDate,
    DateTime actualDate,
    String type,
  ) async {
    try {
      final result = await CycleService.submitCorrection(
        expectedStartDate: expectedDate,
        actualStartDate: actualDate,
        correctionType: type,
      );
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terima kasih! Data siklus telah diperbarui 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan koreksi'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error saving correction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================
  // KONFIRMASI KETIKA MELEWATI PREDIKSI
  // ============================================
  static Future<void> showMissedPeriodConfirmation({
    required BuildContext context,
    required DateTime expectedDate,
    required Function(DateTime?) onConfirmed,
  }) async {
    DateTime? selectedDate;
    bool isDelayed = true;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 10),
              const Text('Haid Terlambat?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prediksi haid sudah lewat. Mohon konfirmasi:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Sudah Haid'),
                      selected: !isDelayed,
                      onSelected: (selected) {
                        setState(() {
                          isDelayed = !selected;
                        });
                      },
                      selectedColor: AppColors.menstruation.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Belum Haid'),
                      selected: isDelayed,
                      onSelected: (selected) {
                        setState(() {
                          isDelayed = selected;
                        });
                      },
                      selectedColor: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              if (!isDelayed) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tanggal mulai haid:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                    title: Text(
                      selectedDate != null
                          ? DateFormat('EEEE, dd MMMM yyyy', 'id').format(selectedDate!)
                          : 'Pilih tanggal',
                    ),
                    trailing: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: expectedDate,
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
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirmed(null);
              },
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (!isDelayed && selectedDate != null) {
                  onConfirmed(selectedDate);
                } else {
                  onConfirmed(null);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
  }
}