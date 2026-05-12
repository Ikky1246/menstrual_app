// lib/models/cycle_model.dart
// Model untuk data siklus menstruasi - Sesuai dengan API Laravel

class CycleData {
  // ============================================
  // FIELD - Sesuai dengan response API Laravel
  // ============================================
  
  // ID dari MongoDB (String, contoh: "6a017b45ecc9c6f6c804f0ad")
  final String? id;
  
  // ID integer untuk cycle (auto increment)
  final int? idCycle;
  
  // ID user (integer)
  final int? userId;
  
  // Tanggal mulai haid terakhir (WAJIB)
  final DateTime lastPeriodDate;
  
  // Tanggal mulai haid sebelumnya (OPSIONAL)
  final DateTime? previousPeriodDate;
  
  // Panjang siklus dalam hari (default 28, hasil prediksi AI)
  final int? cycleLengthDays;
  
  // Tingkat nyeri (0-10) - WAJIB
  final int? painLevel;
  
  // Tingkat stres (0-10) - WAJIB
  final int? stressScoreCycle;
  
  // Rata-rata jam tidur per hari (0-24) - WAJIB
  final double? sleepHoursCycle;
  
  // Rata-rata mood (1-10) - OPSIONAL
  final int? moodScore;
  
  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ============================================
  // CONSTRUCTOR
  // ============================================
  
  CycleData({
    this.id,
    this.idCycle,
    this.userId,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    this.cycleLengthDays,
    this.painLevel,
    this.stressScoreCycle,
    this.sleepHoursCycle,
    this.moodScore,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================
  // FROM JSON (Response dari API Laravel)
  // ============================================
  
  factory CycleData.fromJson(Map<String, dynamic> json) {
    // Helper function untuk parse tanggal dengan aman
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          print('Error parsing date: $dateValue - $e');
          return null;
        }
      }
      return null;
    }
    
    // Helper function untuk parse int dengan aman
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    // Helper function untuk parse double dengan aman
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    return CycleData(
      // ID dari MongoDB (String)
      id: json['id']?.toString(),
      
      // ID cycle integer
      idCycle: parseInt(json['id_cycle']),
      
      // ID user
      userId: parseInt(json['user_id']),
      
      // Tanggal (WAJIB)
      lastPeriodDate: parseDate(json['last_period_date']) ?? DateTime.now(),
      
      // Tanggal sebelumnya (OPSIONAL)
      previousPeriodDate: parseDate(json['previous_period_date']),
      
      // Panjang siklus
      cycleLengthDays: parseInt(json['cycle_length_days']) ?? 28,
      
      // Tingkat nyeri
      painLevel: parseInt(json['pain_level']) ?? 0,
      
      // Tingkat stres
      stressScoreCycle: parseInt(json['stress_score_cycle']) ?? 0,
      
      // Jam tidur
      sleepHoursCycle: parseDouble(json['sleep_hours_cycle']) ?? 7.0,
      
      // Mood score
      moodScore: parseInt(json['mood_score']) ?? 7,
      
      // Timestamps
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  // ============================================
  // TO JSON (Request ke API Laravel)
  // ============================================
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (idCycle != null) 'id_cycle': idCycle,
      if (userId != null) 'user_id': userId,
      'last_period_date': lastPeriodDate.toIso8601String().split('T')[0],
      if (previousPeriodDate != null) 
        'previous_period_date': previousPeriodDate!.toIso8601String().split('T')[0],
      if (cycleLengthDays != null) 'cycle_length_days': cycleLengthDays,
      if (painLevel != null) 'pain_level': painLevel,
      if (stressScoreCycle != null) 'stress_score_cycle': stressScoreCycle,
      if (sleepHoursCycle != null) 'sleep_hours_cycle': sleepHoursCycle,
      if (moodScore != null) 'mood_score': moodScore,
    };
  }

  // ============================================
  // GETTERS (Untuk kemudahan akses)
  // ============================================
  
  // Mendapatkan ID sebagai String
  String get idString => id ?? '';
  
  // Mendapatkan ID cycle integer
  int get idCycleValue => idCycle ?? 0;
  
  // Mendapatkan panjang siklus (default 28)
  int get cycleLength => cycleLengthDays ?? 28;
  
  // Mendapatkan tingkat nyeri (default 0)
  int get painLevelValue => painLevel ?? 0;
  
  // Mendapatkan tingkat stres (default 0)
  int get stressLevel => stressScoreCycle ?? 0;
  
  // Mendapatkan jam tidur (default 7)
  double get sleepHours => sleepHoursCycle ?? 7.0;
  
  // Mendapatkan mood score (default 7)
  int get moodScoreValue => moodScore ?? 7;
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  // Menghitung tanggal haid berikutnya (prediksi)
  DateTime? get nextPeriodDate {
    if (cycleLengthDays == null) return null;
    return lastPeriodDate.add(Duration(days: cycleLengthDays!));
  }
  
  // Menghitung tanggal ovulasi (14 hari sebelum haid berikutnya)
  DateTime? get ovulationDate {
    final nextPeriod = nextPeriodDate;
    if (nextPeriod == null) return null;
    return nextPeriod.subtract(const Duration(days: 14));
  }
  
  // Menghitung hari sampai haid berikutnya
  int get daysUntilNextPeriod {
    final nextPeriod = nextPeriodDate;
    if (nextPeriod == null) return 0;
    final days = nextPeriod.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
  
  // Menghitung window subur (5 hari sebelum ovulasi sampai ovulasi)
  DateTime? get fertileWindowStart {
    final ovulation = ovulationDate;
    if (ovulation == null) return null;
    return ovulation.subtract(const Duration(days: 5));
  }
  
  DateTime? get fertileWindowEnd => ovulationDate;
  
  // Format tanggal haid terakhir
  String get formattedLastPeriodDate {
    return _formatDate(lastPeriodDate);
  }
  
  // Format tanggal haid berikutnya
  String get formattedNextPeriodDate {
    final nextPeriod = nextPeriodDate;
    if (nextPeriod == null) return '-';
    return _formatDate(nextPeriod);
  }
  
  // Format tanggal ovulasi
  String get formattedOvulationDate {
    final ovulation = ovulationDate;
    if (ovulation == null) return '-';
    return _formatDate(ovulation);
  }
  
  // Format tanggal untuk display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  // Format tanggal lengkap
  String get formattedLastPeriodDateFull {
    return _formatDateFull(lastPeriodDate);
  }
  
  String get formattedNextPeriodDateFull {
    final nextPeriod = nextPeriodDate;
    if (nextPeriod == null) return '-';
    return _formatDateFull(nextPeriod);
  }
  
  String _formatDateFull(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  // ============================================
  // COPY WITH (Untuk update data)
  // ============================================
  
  CycleData copyWith({
    String? id,
    int? idCycle,
    int? userId,
    DateTime? lastPeriodDate,
    DateTime? previousPeriodDate,
    int? cycleLengthDays,
    int? painLevel,
    int? stressScoreCycle,
    double? sleepHoursCycle,
    int? moodScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleData(
      id: id ?? this.id,
      idCycle: idCycle ?? this.idCycle,
      userId: userId ?? this.userId,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      previousPeriodDate: previousPeriodDate ?? this.previousPeriodDate,
      cycleLengthDays: cycleLengthDays ?? this.cycleLengthDays,
      painLevel: painLevel ?? this.painLevel,
      stressScoreCycle: stressScoreCycle ?? this.stressScoreCycle,
      sleepHoursCycle: sleepHoursCycle ?? this.sleepHoursCycle,
      moodScore: moodScore ?? this.moodScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // ============================================
  // EMPTY CYCLE (Untuk data kosong)
  // ============================================
  
  static CycleData empty() {
    return CycleData(
      lastPeriodDate: DateTime.now(),
    );
  }
  
  // ============================================
  // TO STRING (Untuk debugging)
  // ============================================
  
  @override
  String toString() {
    return 'CycleData{'
        'id: $id, '
        'idCycle: $idCycle, '
        'userId: $userId, '
        'lastPeriodDate: $lastPeriodDate, '
        'cycleLengthDays: $cycleLengthDays, '
        'painLevel: $painLevel, '
        'stressScoreCycle: $stressScoreCycle, '
        'sleepHoursCycle: $sleepHoursCycle, '
        'moodScore: $moodScore'
        '}';
  }
  
  // ============================================
  // EQUALITY & HASHCODE
  // ============================================
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CycleData &&
        other.id == id &&
        other.idCycle == idCycle &&
        other.userId == userId &&
        other.lastPeriodDate == lastPeriodDate &&
        other.cycleLengthDays == cycleLengthDays;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      idCycle,
      userId,
      lastPeriodDate,
      cycleLengthDays,
    );
  }
}

// ============================================
// MODEL UNTUK RESPONSE PREDIKSI
// ============================================

class PredictionResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final double? predictedCycleLength;
  final String? nextPeriodDate;
  final double? errorMargin;
  final String? confidenceLevel;

  PredictionResponse({
    required this.success,
    this.message,
    this.data,
    this.predictedCycleLength,
    this.nextPeriodDate,
    this.errorMargin,
    this.confidenceLevel,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return PredictionResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: data,
      predictedCycleLength: data?['predicted_cycle_length']?.toDouble(),
      nextPeriodDate: data?['next_period_date'],
      errorMargin: data?['error_margin']?.toDouble(),
      confidenceLevel: data?['confidence_level'],
    );
  }
}

// ============================================
// MODEL UNTUK REQUEST PREDIKSI
// ============================================

class PredictionRequest {
  final String tanggalHaidTerakhir;
  final String? tanggalHaidBulanSebelumnya;
  final int painLevel;
  final int stressScore;
  final double sleepHours;
  final int? moodScore;

  PredictionRequest({
    required this.tanggalHaidTerakhir,
    this.tanggalHaidBulanSebelumnya,
    required this.painLevel,
    required this.stressScore,
    required this.sleepHours,
    this.moodScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'tanggal_haid_terakhir': tanggalHaidTerakhir,
      if (tanggalHaidBulanSebelumnya != null) 
        'tanggal_haid_bulan_sebelumnya': tanggalHaidBulanSebelumnya,
      'pain_level': painLevel,
      'stress_score_cycle': stressScore,
      'sleep_hours_cycle': sleepHours,
      if (moodScore != null) 'mood_score': moodScore,
    };
  }
}