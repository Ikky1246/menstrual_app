import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:menstrual_app/services/auth_service.dart';

class CycleService {
  static const String baseUrl = "http://localhost:8000/api";

  // Simpan data siklus wajib
  static Future<Map<String, dynamic>> saveCycleData({
    required String lastPeriodDate,
    String? previousPeriodDate,
    required int cycleLength,
    required int periodDuration,
    int? stressLevel,
    double? sleepHours,
    int? healthScore,
    List<String>? symptoms,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cycle'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'last_period_date': lastPeriodDate,
          'previous_period_date': previousPeriodDate,
          'cycle_length': cycleLength,
          'period_duration': periodDuration,
          'stress_level': stressLevel,
          'sleep_hours': sleepHours,
          'health_score': healthScore,
          'symptoms': symptoms,
          'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyimpan data'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Dapatkan riwayat siklus
  static Future<Map<String, dynamic>> getCycleHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/cycle/history'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update data siklus
  static Future<Map<String, dynamic>> updateCycleData({
    required String cycleId,
    String? lastPeriodDate,
    String? previousPeriodDate,
    int? cycleLength,
    int? periodDuration,
    int? stressLevel,
    double? sleepHours,
    int? healthScore,
    List<String>? symptoms,
    String? notes,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final Map<String, dynamic> data = {};
      if (lastPeriodDate != null) data['last_period_date'] = lastPeriodDate;
      if (previousPeriodDate != null) data['previous_period_date'] = previousPeriodDate;
      if (cycleLength != null) data['cycle_length'] = cycleLength;
      if (periodDuration != null) data['period_duration'] = periodDuration;
      if (stressLevel != null) data['stress_level'] = stressLevel;
      if (sleepHours != null) data['sleep_hours'] = sleepHours;
      if (healthScore != null) data['health_score'] = healthScore;
      if (symptoms != null) data['symptoms'] = symptoms;
      if (notes != null) data['notes'] = notes;

      final response = await http.put(
        Uri.parse('$baseUrl/cycle/$cycleId'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update data'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}