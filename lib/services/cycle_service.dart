import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class CycleService {
  // ==============================================
  // SAVE MANDATORY CYCLE DATA (Wajib dari onboarding)
  // ==============================================
  static Future<Map<String, dynamic>> saveMandatoryData({
    required int idUser,
    required String lastPeriodDate,
    String? previousPeriodDate,
    required int cycleLengthDays,
    required int periodDurationDays,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      print('📤 Saving mandatory cycle data...');
      print('   id_user: $idUser');
      print('   last_period_date: $lastPeriodDate');
      print('   cycle_length_days: $cycleLengthDays');
      print('   period_duration_days: $periodDurationDays');

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiCycleCreate}'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'id_user': idUser,
          'last_period_date': lastPeriodDate,
          'previous_period_date': previousPeriodDate,
          'cycle_length_days': cycleLengthDays,
          'period_duration_days': periodDurationDays,
        }),
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      print('📊 Response: ${response.statusCode} - $data');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'data': data, 'cycleId': data['_id'] ?? data['id']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyimpan data siklus'
        };
      }
    } catch (e) {
      print('❌ Error saving cycle data: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // UPDATE WITH OPTIONAL DATA (Opsional dari onboarding)
  // ==============================================
  static Future<Map<String, dynamic>> updateOptionalData({
  required String cycleId,
  int? stressScoreCycle,
  double? sleepHoursCycle,
  List<String>? symptoms,
  String? notes,
}) async {
  try {
    final token = await AuthService.getToken();
    
    print('📤 Updating optional data - Token: ${token != null ? "Ada" : "TIDAK ADA"}');
    print('📤 Cycle ID: $cycleId');
    
    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan. Silakan login ulang.'};
    }

    final Map<String, dynamic> data = {};
    if (stressScoreCycle != null) data['stress_score_cycle'] = stressScoreCycle;
    if (sleepHoursCycle != null) data['sleep_hours_cycle'] = sleepHoursCycle;
    if (symptoms != null && symptoms.isNotEmpty) data['symptoms'] = symptoms;
    if (notes != null && notes.isNotEmpty) data['notes'] = notes;

    print('📤 Request body: $data');

    final url = Uri.parse('${AppConstants.apiBaseUrl}/cycle/$cycleId');
    print('📤 URL: $url');

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    ).timeout(AppDurations.apiTimeout);

    print('📊 Update optional response status: ${response.statusCode}');
    print('📊 Response body: ${response.body}');

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
    print('❌ Error updating optional data: $e');
    return {'success': false, 'message': 'Error: $e'};
  }
}

  // ==============================================
  // GET ALL CYCLES (Riwayat)
  // ==============================================
  static Future<Map<String, dynamic>> getAllCycles() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan', 'cycles': []};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiCycle}'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      print('📊 Get cycles response: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<CycleData> cycles = [];
        if (data['data'] != null && data['data'] is List) {
          cycles = (data['data'] as List)
              .map((item) => CycleData.fromJson(item))
              .toList();
        } else if (data is List) {
          cycles = (data as List)
              .map((item) => CycleData.fromJson(item))
              .toList();
        }
        return {'success': true, 'cycles': cycles};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengambil data',
          'cycles': []
        };
      }
    } catch (e) {
      print('❌ Error getting cycles: $e');
      return {'success': false, 'message': 'Error: $e', 'cycles': []};
    }
  }

  // ==============================================
  // GET LATEST CYCLE
  // ==============================================
  static Future<Map<String, dynamic>> getLatestCycle() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiCycle}/latest'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      print('📊 Get latest cycle response: ${response.statusCode}');

      if (response.statusCode == 200) {
        CycleData? cycle;
        if (data['data'] != null) {
          cycle = CycleData.fromJson(data['data']);
        } else if (data) {
          cycle = CycleData.fromJson(data);
        }
        return {'success': true, 'cycle': cycle};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Tidak ada data'};
      }
    } catch (e) {
      print('❌ Error getting latest cycle: $e');
      return {'success': false, 'message': 'Error: $e'};
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