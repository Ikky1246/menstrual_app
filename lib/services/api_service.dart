import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

class ApiService {
  // ==============================================
  // GET TOKEN
  // ==============================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  // ==============================================
  // PREDIKSI DENGAN AI (VERSI TERBARU - MATCH DENGAN LARAVEL)
  // ==============================================
  static Future<Map<String, dynamic>> predictCycle({
    required String tanggalHaidTerakhir,
    String? tanggalHaidBulanSebelumnya,
    required int painLevel,
    required int stressScore,
    required double sleepHours,
    int? moodScore,
  }) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login kembali.',
        };
      }

      // Siapkan payload sesuai dengan yang dibutuhkan Laravel
      Map<String, dynamic> payload = {
        'tanggal_haid_terakhir': tanggalHaidTerakhir,
        'pain_level': painLevel,
        'stress_score_cycle': stressScore,
        'sleep_hours_cycle': sleepHours,
      };
      
      // Optional fields (hanya tambahkan jika tidak null)
      if (tanggalHaidBulanSebelumnya != null && tanggalHaidBulanSebelumnya.isNotEmpty) {
        payload['tanggal_haid_bulan_sebelumnya'] = tanggalHaidBulanSebelumnya;
      }
      
      if (moodScore != null) payload['mood_score'] = moodScore;

      print('📤 Sending prediction request to: ${AppConstants.baseUrl}/api/mobile/predict');
      print('📦 Payload: $payload');
      print('🔑 Token: ${token.substring(0, math.min(20, token.length))}...');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/predict'),
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
        Uri.parse('${AppConstants.baseUrl}/api/mobile/predictions/health'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));
      
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
        Uri.parse('${AppConstants.baseUrl}/api/mobile/predictions/history'),
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