class CycleData {
  final int? id;
  final int? userId;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int? cycleLength; // Panjang siklus dalam hari
  final int? periodDuration; // Lama haid dalam hari
  final int? stressLevel; // 1-10 (opsional)
  final double? sleepHours; // Jam tidur (opsional)
  final int? healthScore; // 1-10 (opsional)
  final DateTime? nextPeriodDate; // Prediksi tanggal haid berikutnya
  final DateTime? ovulationDate; // Prediksi tanggal ovulasi
  final List<String>? symptoms; // Gejala yang dialami
  final String? notes; // Catatan tambahan
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CycleData({
    this.id,
    this.userId,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    this.cycleLength,
    this.periodDuration,
    this.stressLevel,
    this.sleepHours,
    this.healthScore,
    this.nextPeriodDate,
    this.ovulationDate,
    this.symptoms,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // Untuk konversi dari JSON (response dari API)
  factory CycleData.fromJson(Map<String, dynamic> json) {
    return CycleData(
      id: json['id'],
      userId: json['user_id'],
      lastPeriodDate: DateTime.parse(json['last_period_date']),
      previousPeriodDate: json['previous_period_date'] != null 
          ? DateTime.parse(json['previous_period_date']) 
          : null,
      cycleLength: json['cycle_length'],
      periodDuration: json['period_duration'],
      stressLevel: json['stress_level'],
      sleepHours: json['sleep_hours']?.toDouble(),
      healthScore: json['health_score'],
      nextPeriodDate: json['next_period_date'] != null 
          ? DateTime.parse(json['next_period_date']) 
          : null,
      ovulationDate: json['ovulation_date'] != null 
          ? DateTime.parse(json['ovulation_date']) 
          : null,
      symptoms: json['symptoms'] != null 
          ? List<String>.from(json['symptoms']) 
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Untuk konversi ke JSON (request ke API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'last_period_date': lastPeriodDate.toIso8601String().split('T')[0],
      'previous_period_date': previousPeriodDate?.toIso8601String().split('T')[0],
      'cycle_length': cycleLength,
      'period_duration': periodDuration,
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      'health_score': healthScore,
      'next_period_date': nextPeriodDate?.toIso8601String().split('T')[0],
      'ovulation_date': ovulationDate?.toIso8601String().split('T')[0],
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  // Copy with method untuk update data
  CycleData copyWith({
    int? id,
    int? userId,
    DateTime? lastPeriodDate,
    DateTime? previousPeriodDate,
    int? cycleLength,
    int? periodDuration,
    int? stressLevel,
    double? sleepHours,
    int? healthScore,
    DateTime? nextPeriodDate,
    DateTime? ovulationDate,
    List<String>? symptoms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      previousPeriodDate: previousPeriodDate ?? this.previousPeriodDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      healthScore: healthScore ?? this.healthScore,
      nextPeriodDate: nextPeriodDate ?? this.nextPeriodDate,
      ovulationDate: ovulationDate ?? this.ovulationDate,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model untuk menyimpan data siklus di lokal (SharedPreferences)
class CycleLocalData {
  final int? id;
  final DateTime lastPeriodDate;
  final DateTime? previousPeriodDate;
  final int? periodDuration;
  final int? stressLevel;
  final double? sleepHours;
  final int? healthScore;

  CycleLocalData({
    this.id,
    required this.lastPeriodDate,
    this.previousPeriodDate,
    this.periodDuration,
    this.stressLevel,
    this.sleepHours,
    this.healthScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'last_period_date': lastPeriodDate.toIso8601String(),
      'previous_period_date': previousPeriodDate?.toIso8601String(),
      'period_duration': periodDuration,
      'stress_level': stressLevel,
      'sleep_hours': sleepHours,
      'health_score': healthScore,
    };
  }

  factory CycleLocalData.fromMap(Map<String, dynamic> map) {
    return CycleLocalData(
      id: map['id'],
      lastPeriodDate: DateTime.parse(map['last_period_date']),
      previousPeriodDate: map['previous_period_date'] != null 
          ? DateTime.parse(map['previous_period_date']) 
          : null,
      periodDuration: map['period_duration'],
      stressLevel: map['stress_level'],
      sleepHours: map['sleep_hours']?.toDouble(),
      healthScore: map['health_score'],
    );
  }
}

// Enum untuk gejala yang umum
enum Symptom {
  cramp('Kram perut'),
  headache('Sakit kepala'),
  fatigue('Lelah'),
  bloating('Kembung'),
  breastTenderness('Payudara nyeri'),
  acne('Jerawat'),
  moodSwings('Perubahan mood'),
  backPain('Sakit punggung'),
  nausea('Mual'),
  diarrhea('Diare');

  final String displayName;
  const Symptom(this.displayName);

  static Symptom fromString(String value) {
    return Symptom.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => Symptom.cramp,
    );
  }
}

// Model untuk request prediksi (mirip dengan ApiService)
class PredictionRequest {
  final int cycleLength;
  final int stress;
  final double sleep;
  final int health;
  final String startDate;
  final int? previousCycleLength; // Opsional, untuk akurasi lebih baik

  PredictionRequest({
    required this.cycleLength,
    required this.stress,
    required this.sleep,
    required this.health,
    required this.startDate,
    this.previousCycleLength,
  });

  Map<String, dynamic> toJson() {
    return {
      'cycle_length_days': cycleLength,
      'stress_score_cycle': stress,
      'sleep_hours_cycle': sleep,
      'overall_health_score': health,
      'start_date': startDate,
      'previous_cycle_length': previousCycleLength,
    };
  }
}

// Model untuk response prediksi
class PredictionResponse {
  final double predictedCycleLength;
  final String nextPeriodDate;
  final String? ovulationDate;
  final String? fertilityWindow;

  PredictionResponse({
    required this.predictedCycleLength,
    required this.nextPeriodDate,
    this.ovulationDate,
    this.fertilityWindow,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      predictedCycleLength: (json['predicted_cycle_length'] ?? 28).toDouble(),
      nextPeriodDate: json['next_period_date'] ?? '',
      ovulationDate: json['ovulation_date'],
      fertilityWindow: json['fertility_window'],
    );
  }
}