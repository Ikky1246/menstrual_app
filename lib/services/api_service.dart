import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static Future<Map<String, dynamic>> predictCycle({
    required int cycleLength,
    required int stress,
    required int sleep,
    required int health,
    required String startDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiPredict}'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cycle_length_days": cycleLength,
          "stress_score_cycle": stress,
          "sleep_hours_cycle": sleep,
          "overall_health_score": health,
          "start_date": startDate
        }),
      ).timeout(AppDurations.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}