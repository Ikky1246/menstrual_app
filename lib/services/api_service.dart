import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  // ==============================================
  // PREDICT CYCLE - menggunakan Multiple Linear Regression
  // ==============================================
  static Future<Map<String, dynamic>> predictCycle({
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

      print('📤 Predicting cycle...');
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
  // PRIVATE: GET TOKEN
  // ==============================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }
}