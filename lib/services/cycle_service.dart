import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cycle_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class CycleService {
  static void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // ==============================================
  // GET TOKEN DENGAN VALIDASI
  // ==============================================
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Coba ambil dari AppConstants.keyToken
    String? token = prefs.getString(AppConstants.keyToken);
    
    // Jika tidak ada, coba dari key lain
    if (token == null) {
      token = prefs.getString('token');
    }
    
    if (token == null) {
      token = prefs.getString('auth_token');
    }
    
    if (kDebugMode) {
      print('🔑 Token status: ${token != null ? "Ada (${token.substring(0, math.min(20, token.length))}...)" : "TIDAK ADA"}');
    }
    
    return token;
  }

  // ==============================================
  // REFRESH/RELOGIN (jika token expired)
  // ==============================================
  static Future<bool> _refreshToken() async {
    _log('🔄 Mencoba refresh token...');
    
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final password = prefs.getString('user_password');
    
    if (email != null && password != null) {
      _log('🔄 Mencoba login ulang dengan email: $email');
      final result = await AuthService.login(email: email, password: password);
      
      if (result['success'] == true) {
        _log('✅ Refresh token berhasil!');
        return true;
      }
    }
    
    _log('❌ Refresh token gagal!');
    return false;
  }

  // ==============================================
  // SAVE MANDATORY CYCLE DATA
  // ==============================================
  static Future<Map<String, dynamic>> saveMandatoryData({
    required int idUser,
    required String lastPeriodDate,
    String? previousPeriodDate,
    required int cycleLengthDays,
    required int periodDurationDays,
    required int painLevel,
    required int stressLevel,
    required double sleepHours,
    required int moodLevel,
  }) async {
    try {
      String? token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan. Silakan login kembali.'};
      }

      _log('📤 Saving mandatory cycle data...');
      _log('   id_user: $idUser');
      _log('   last_period_date: $lastPeriodDate');

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
          'pain_level': painLevel,
          'stress_score_cycle': stressLevel,
          'sleep_hours_cycle': sleepHours,
          'mood_score': moodLevel,
        }),
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
          'cycleId': data['_id'] ?? data['id'] ?? data['data']?['_id']
        };
      } else if (response.statusCode == 401) {
        // Token expired, coba refresh
        _log('⚠️ Token expired, mencoba refresh...');
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry dengan token baru
          return await saveMandatoryData(
            idUser: idUser,
            lastPeriodDate: lastPeriodDate,
            previousPeriodDate: previousPeriodDate,
            cycleLengthDays: cycleLengthDays,
            periodDurationDays: periodDurationDays,
            painLevel: painLevel,
            stressLevel: stressLevel,
            sleepHours: sleepHours,
            moodLevel: moodLevel,
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
  // UPDATE WITH OPTIONAL DATA
  // ==============================================
static Future<Map<String, dynamic>> updateOptionalData({
  required String cycleId,
  required int painLevel,
  required int stressScoreCycle,
  required double sleepHoursCycle,
  required int moodLevel,
  double? weight,
  double? height,
  List<String>? symptoms,
  String? notes,
}) async {
  try {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan'
      };
    }

    // ✅ CEK APAKAH CYCLE ID MILIK USER INI
    final Map<String, dynamic> data = {
      'pain_level': painLevel,
      'stress_score_cycle': stressScoreCycle,
      'sleep_hours_cycle': sleepHoursCycle,
      'mood_score': moodLevel,
    };

    if (weight != null) data['weight_kg'] = weight;
    if (height != null) data['height_cm'] = height;
    if (symptoms != null && symptoms.isNotEmpty) {
      data['symptoms'] = symptoms;
    }
    if (notes != null && notes.isNotEmpty) {
      data['notes'] = notes;
    }

    final url = Uri.parse(
      '${AppConstants.apiBaseUrl}${AppConstants.apiCycleUpdate}$cycleId',
    );

    print('📤 URL: $url');
    print('📤 METHOD: PUT'); // ✅ GANTI ke PUT jika backend pakai PUT
    print('📤 TOKEN: Bearer $token');
    print('📤 BODY: ${jsonEncode(data)}');

    final response = await http.put(  // ✅ atau .patch tergantung backend
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    ).timeout(AppDurations.apiTimeout);

    print('📊 STATUS: ${response.statusCode}');
    print('📊 RESPONSE: ${response.body}');

    // ✅ HANDLE KHUSUS 403
    if (response.statusCode == 403) {
      Map<String, dynamic> errorData = {};
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {}
      
      // Cek apakah perlu verifikasi email
      if (errorData['message']?.contains('verifikasi') == true) {
        return {
          'success': false,
          'message': 'Silakan verifikasi email Anda terlebih dahulu',
          'need_verification': true,
        };
      }
      
      // Cek apakah perlu refresh token
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await updateOptionalData(
          cycleId: cycleId,
          painLevel: painLevel,
          stressScoreCycle: stressScoreCycle,
          sleepHoursCycle: sleepHoursCycle,
          moodLevel: moodLevel,
          weight: weight,
          height: height,
          symptoms: symptoms,
          notes: notes,
        );
      }
    }

    Map<String, dynamic> responseData = {};
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': responseData,
      };
    }

    return {
      'success': false,
      'message': responseData['message'] ?? 'Gagal update cycle',
    };
  } catch (e) {
    print('❌ ERROR UPDATE CYCLE: $e');
    return {
      'success': false,
      'message': 'Error: $e',
    };
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
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiCycle}'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Get cycles response: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<CycleData> cycles = [];
        
        final List<dynamic> cyclesData;
        if (data['data'] != null && data['data'] is List) {
          cyclesData = data['data'] as List<dynamic>;
        } else if (data is List) {
          cyclesData = data as List<dynamic>;
        } else {
          cyclesData = [];
        }
        
        cycles = cyclesData
            .map((item) => CycleData.fromJson(item as Map<String, dynamic>))
            .toList();
            
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
      _log('📊 Get latest cycle response: ${response.statusCode}');

      if (response.statusCode == 200) {
        CycleData? cycle;
        if (data['data'] != null) {
          cycle = CycleData.fromJson(data['data'] as Map<String, dynamic>);
        } else if (data is Map<String, dynamic>) {
          cycle = CycleData.fromJson(data);
        }
        return {'success': true, 'cycle': cycle};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Tidak ada data'};
      }
    } catch (e) {
      _log('❌ Error getting latest cycle: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}