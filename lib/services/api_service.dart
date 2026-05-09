import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // ==============================================
  // GET TOKEN
  // ==============================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  // ==============================================
  // PREDIKSI DENGAN AI (VERSI BARU)
  // ==============================================
  static Future<Map<String, dynamic>> predictCycle({
    required DateTime lastCycleStartDate,
    DateTime? previousCycleStartDate,
    required int painLevel,
    required int stressScore,
    required double sleepHours,
    int? moodScore,
    int? age,
    double? weightKg,
    double? heightCm,
    bool? pcosDiagnosed,
    bool? birthControlUse,
  }) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      // Format tanggal ke YYYY-MM-DD
      String formatDate(DateTime date) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }

      // Siapkan payload sesuai dengan yang dibutuhkan Laravel
      Map<String, dynamic> payload = {
        'last_cycle_start_date': formatDate(lastCycleStartDate),
        'pain_level': painLevel,
        'stress_score_cycle': stressScore,
        'sleep_hours_cycle': sleepHours,
      };
      
      // Optional fields (hanya tambahkan jika tidak null)
      if (previousCycleStartDate != null) {
        payload['previous_cycle_start_date'] = formatDate(previousCycleStartDate);
      }
      
      if (moodScore != null) payload['mood_score'] = moodScore;
      if (age != null) payload['age'] = age;
      if (weightKg != null) payload['weight_kg'] = weightKg;
      if (heightCm != null) payload['height_cm'] = heightCm;
      if (pcosDiagnosed != null) payload['pcos_diagnosed'] = pcosDiagnosed;
      if (birthControlUse != null) payload['birth_control_use'] = birthControlUse;

      print('📤 Sending prediction request to: ${AppConstants.baseUrl}/api/predictions');
      print('📦 Payload: $payload');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/predictions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      ).timeout(AppDurations.apiTimeout);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true) {
          return {
            'success': true,
            'data': result['data'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Prediksi gagal',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesi habis, silakan login kembali',
        };
      } else if (response.statusCode == 422) {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Validasi gagal: ${error['errors'] ?? error['message']}',
        };
      } else if (response.statusCode == 503) {
        return {
          'success': false,
          'message': 'Layanan AI sedang sibuk, coba lagi nanti',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan (${response.statusCode})',
        };
      }
    } catch (e) {
      print('❌ Predict API error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: $e',
      };
    }
  }

  // ==============================================
  // PREDIKSI LAMA (MASIH DISIMPAN UNTUK KOMPATIBILITAS)
  // ==============================================
  static Future<Map<String, dynamic>> predictCycleOld({
    required int cycleLengthDays,
    required int stressScoreCycle,
    required double sleepHoursCycle,
    required String startDate,
  }) async {
    try {
      final token = await _getToken();
      
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }

      print('📤 Predicting cycle (old method)...');
      print('   cycle_length_days: $cycleLengthDays');
      print('   stress_score_cycle: $stressScoreCycle');
      print('   sleep_hours_cycle: $sleepHoursCycle');
      print('   start_date: $startDate');

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiPrediction}'),
        headers: headers,
        body: jsonEncode({
          "cycle_length_days": cycleLengthDays,
          "stress_score_cycle": stressScoreCycle,
          "sleep_hours_cycle": sleepHoursCycle,
          "start_date": startDate,
        }),
      ).timeout(AppDurations.apiTimeout);

      print('📊 Prediction response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Prediksi berhasil'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal melakukan prediksi'
        };
      }
    } catch (e) {
      print('❌ Prediction error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e'
      };
    }
  }

  // ==============================================
  // CEK STATUS KESEHATAN AI SERVICE
  // ==============================================
  static Future<Map<String, dynamic>> checkAIHealth() async {
    try {
      final token = await _getToken();
      
      final headers = {
        "Content-Type": "application/json",
      };
      
      if (token != null) {
        headers["Authorization"] = "Bearer $token";
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/predictions/health'),
        headers: headers,
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'unavailable'};
      }
    } catch (e) {
      return {'status': 'unavailable', 'error': e.toString()};
    }
  }

  // ==============================================
  // AMBIL RIWAYAT PREDIKSI
  // ==============================================
  static Future<List<dynamic>> getPredictionHistory() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return [];
      }
      
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/predictions/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppDurations.apiTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      print('❌ Get history error: $e');
      return [];
    }
  }
}