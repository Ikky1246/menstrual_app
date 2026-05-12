import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class CycleService {
  static void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // ==============================================
  // GET TOKEN
  // ==============================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(AppConstants.keyToken);
    
    if (token == null) {
      token = prefs.getString('token');
    }
    
    return token;
  }

  // ==============================================
  // SAVE CYCLE DATA (Sesuai dengan backend Laravel)
  // ==============================================
  static Future<Map<String, dynamic>> saveCycle({
    required String lastPeriodDate,
    String? previousPeriodDate,
    required int cycleLengthDays,
    required int painLevel,
    required int stressScoreCycle,
    required double sleepHoursCycle,
    int? moodScore,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan. Silakan login kembali.'};
      }

      _log('📤 Saving cycle data...');
      _log('   last_period_date: $lastPeriodDate');

      final Map<String, dynamic> payload = {
        'last_period_date': lastPeriodDate,
        'cycle_length_days': cycleLengthDays,
        'pain_level': painLevel,
        'stress_score_cycle': stressScoreCycle,
        'sleep_hours_cycle': sleepHoursCycle,
      };

      if (previousPeriodDate != null) {
        payload['previous_period_date'] = previousPeriodDate;
      }
      if (moodScore != null) {
        payload['mood_score'] = moodScore;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/cycle'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Response: ${response.statusCode}');
      _log('📊 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Data siklus berhasil disimpan'
        };
      } else if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return await saveCycle(
            lastPeriodDate: lastPeriodDate,
            previousPeriodDate: previousPeriodDate,
            cycleLengthDays: cycleLengthDays,
            painLevel: painLevel,
            stressScoreCycle: stressScoreCycle,
            sleepHoursCycle: sleepHoursCycle,
            moodScore: moodScore,
          );
        } else {
          return {'success': false, 'message': 'Sesi habis, silakan login kembali'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menyimpan data siklus'
        };
      }
    } catch (e) {
      _log('❌ Error saving cycle data: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // GET LATEST CYCLE (DIPERBAIKI)
  // ==============================================
  static Future<Map<String, dynamic>> getLatestCycle() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/cycle/latest'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      _log('📊 Get latest cycle response: ${response.statusCode}');
      _log('📊 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          try {
            final cycle = CycleData.fromJson(data['data'] as Map<String, dynamic>);
            _log('✅ Cycle parsed successfully: id=${cycle.id}, cycleLength=${cycle.cycleLengthDays}');
            return {'success': true, 'cycle': cycle};
          } catch (e) {
            _log('❌ Error parsing cycle: $e');
            return {'success': false, 'message': 'Error parsing data: $e'};
          }
        }
        return {'success': false, 'message': data['message'] ?? 'Tidak ada data'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Belum ada data siklus'};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data siklus'};
      }
    } catch (e) {
      _log('❌ Error getting latest cycle: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // GET ALL CYCLES
  // ==============================================
  static Future<Map<String, dynamic>> getAllCycles() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan', 'cycles': []};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/cycles'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Get all cycles response: ${response.statusCode}');

      if (response.statusCode == 200 && data['success'] == true) {
        List<CycleData> cycles = [];
        
        final List<dynamic> cyclesData = data['data'] ?? [];
        for (var item in cyclesData) {
          try {
            cycles.add(CycleData.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            _log('❌ Error parsing cycle item: $e');
          }
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
      _log('❌ Error getting cycles: $e');
      return {'success': false, 'message': 'Error: $e', 'cycles': []};
    }
  }

  // ==============================================
  // UPDATE CYCLE (untuk optional form)
  // ==============================================
  static Future<Map<String, dynamic>> updateCycle({
    required String cycleId,
    int? painLevel,
    int? stressScoreCycle,
    double? sleepHoursCycle,
    int? moodScore,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final Map<String, dynamic> payload = {};
      if (painLevel != null) payload['pain_level'] = painLevel;
      if (stressScoreCycle != null) payload['stress_score_cycle'] = stressScoreCycle;
      if (sleepHoursCycle != null) payload['sleep_hours_cycle'] = sleepHoursCycle;
      if (moodScore != null) payload['mood_score'] = moodScore;

      final url = '${AppConstants.baseUrl}/api/mobile/cycle/$cycleId';
      
      _log('📤 Update cycle URL: $url');
      _log('📤 Payload: $payload');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Update cycle response: ${response.statusCode}');
      _log('📊 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Data siklus berhasil diupdate',
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Data siklus tidak ditemukan'
        };
      } else if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return await updateCycle(
            cycleId: cycleId,
            painLevel: painLevel,
            stressScoreCycle: stressScoreCycle,
            sleepHoursCycle: sleepHoursCycle,
            moodScore: moodScore,
          );
        } else {
          return {'success': false, 'message': 'Sesi habis, silakan login kembali'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal update data siklus'
        };
      }
    } catch (e) {
      _log('❌ Error updating cycle: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // DELETE CYCLE
  // ==============================================
  static Future<Map<String, dynamic>> deleteCycle({
    required String cycleId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/cycle/$cycleId'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Delete cycle response: ${response.statusCode}');
      _log('📊 Response body: ${response.body}');

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Data siklus berhasil dihapus'
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Data siklus tidak ditemukan'
        };
      } else if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return await deleteCycle(cycleId: cycleId);
        } else {
          return {'success': false, 'message': 'Sesi habis, silakan login kembali'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal hapus data siklus'
        };
      }
    } catch (e) {
      _log('❌ Error deleting cycle: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // GET CYCLE BY ID
  // ==============================================
  static Future<Map<String, dynamic>> getCycleById({
    required String cycleId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/cycle/$cycleId'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Get cycle by id response: ${response.statusCode}');

      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        try {
          final cycle = CycleData.fromJson(data['data'] as Map<String, dynamic>);
          return {'success': true, 'cycle': cycle};
        } catch (e) {
          return {'success': false, 'message': 'Error parsing data: $e'};
        }
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Data siklus tidak ditemukan'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal mengambil data siklus'};
      }
    } catch (e) {
      _log('❌ Error getting cycle by id: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  // ==============================================
// SUBMIT CORRECTION (Koreksi siklus dari user)
// ==============================================
static Future<Map<String, dynamic>> submitCorrection({
  required DateTime expectedStartDate,
  required DateTime actualStartDate,
  required String correctionType, // 'start' or 'end'
}) async {
  try {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    final payload = {
      'expected_start_date': expectedStartDate.toIso8601String().split('T')[0],
      'actual_start_date': actualStartDate.toIso8601String().split('T')[0],
      'correction_type': correctionType,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/mobile/correction'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    ).timeout(AppDurations.apiTimeout);

    final data = jsonDecode(response.body);
    _log('📊 Correction response: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Koreksi berhasil disimpan',
      };
    } else {
      return {'success': false, 'message': data['message'] ?? 'Gagal menyimpan koreksi'};
    }
  } catch (e) {
    _log('❌ Error submitting correction: $e');
    return {'success': false, 'message': 'Error: $e'};
  }
}
}