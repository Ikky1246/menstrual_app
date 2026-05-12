// lib/models/daily_note_model.dart
// Model untuk catatan harian user (mood, gejala, catatan)

class DailyNote {
  final String? id;
  final int userId;
  final DateTime date;
  final int moodLevel;      // 1-10
  final List<String> symptoms;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyNote({
    this.id,
    required this.userId,
    required this.date,
    required this.moodLevel,
    required this.symptoms,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyNote.fromJson(Map<String, dynamic> json) {
    return DailyNote(
      id: json['id']?.toString(),
      userId: json['user_id'] ?? 0,
      date: DateTime.parse(json['date']),
      moodLevel: json['mood_level'] ?? 5,
      symptoms: json['symptoms'] != null 
          ? List<String>.from(json['symptoms']) 
          : [],
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'mood_level': moodLevel,
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  // Empty note untuk tanggal yang belum ada catatan
  static DailyNote empty(int userId, DateTime date) {
    return DailyNote(
      userId: userId,
      date: date,
      moodLevel: 5,
      symptoms: [],
      notes: '',
    );
  }
}

// Model untuk koreksi siklus (feedback dari user)
class CycleCorrection {
  final String? id;
  final int userId;
  final DateTime expectedStartDate;   // Tanggal prediksi AI
  final DateTime actualStartDate;      // Tanggal sebenarnya
  final DateTime? expectedEndDate;     // Tanggal prediksi selesai
  final DateTime? actualEndDate;       // Tanggal sebenarnya selesai
  final String correctionType;         // 'start' atau 'end'
  final DateTime createdAt;

  CycleCorrection({
    this.id,
    required this.userId,
    required this.expectedStartDate,
    required this.actualStartDate,
    this.expectedEndDate,
    this.actualEndDate,
    required this.correctionType,
    required this.createdAt,
  });

  factory CycleCorrection.fromJson(Map<String, dynamic> json) {
    return CycleCorrection(
      id: json['id']?.toString(),
      userId: json['user_id'] ?? 0,
      expectedStartDate: DateTime.parse(json['expected_start_date']),
      actualStartDate: DateTime.parse(json['actual_start_date']),
      expectedEndDate: json['expected_end_date'] != null 
          ? DateTime.parse(json['expected_end_date']) 
          : null,
      actualEndDate: json['actual_end_date'] != null 
          ? DateTime.parse(json['actual_end_date']) 
          : null,
      correctionType: json['correction_type'] ?? 'start',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'expected_start_date': expectedStartDate.toIso8601String().split('T')[0],
      'actual_start_date': actualStartDate.toIso8601String().split('T')[0],
      if (expectedEndDate != null) 
        'expected_end_date': expectedEndDate!.toIso8601String().split('T')[0],
      if (actualEndDate != null) 
        'actual_end_date': actualEndDate!.toIso8601String().split('T')[0],
      'correction_type': correctionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}