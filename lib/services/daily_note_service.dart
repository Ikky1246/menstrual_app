// lib/services/daily_note_service.dart
// Service untuk CRUD catatan harian

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_note_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class DailyNoteService {
  static void _log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  // ============================================
  // SAVE DAILY NOTE
  // ============================================
  static Future<Map<String, dynamic>> saveNote({
    required DateTime date,
    required int moodLevel,
    required List<String> symptoms,
    required String notes,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final payload = {
        'date': date.toIso8601String().split('T')[0],
        'mood_level': moodLevel,
        'symptoms': symptoms,
        'notes': notes,
      };

      _log('📤 Saving daily note...');
      _log('   Payload: $payload');

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/note'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Save note response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Catatan berhasil disimpan',
          'data': data['data'],
        };
      } else if (response.statusCode == 401) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          return await saveNote(
            date: date,
            moodLevel: moodLevel,
            symptoms: symptoms,
            notes: notes,
          );
        }
        return {'success': false, 'message': 'Sesi habis, silakan login kembali'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Gagal menyimpan catatan'};
      }
    } catch (e) {
      _log('❌ Error saving note: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // GET NOTE BY DATE
  // ============================================
  static Future<Map<String, dynamic>> getNoteByDate(DateTime date) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/note/$dateStr'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Get note response: ${response.statusCode}');

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['data'] != null) {
          return {
            'success': true,
            'note': DailyNote.fromJson(data['data']),
          };
        }
      }
      return {'success': false, 'message': 'Tidak ada catatan untuk tanggal ini'};
    } catch (e) {
      _log('❌ Error getting note: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ============================================
  // GET ALL NOTES FOR MONTH
  // ============================================
  static Future<Map<String, dynamic>> getNotesForMonth(int year, int month) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan', 'notes': {}};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/mobile/notes/$year/$month'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);
      _log('📊 Get notes for month response: ${response.statusCode}');

      if (response.statusCode == 200 && data['success'] == true) {
        Map<String, bool> notesMap = {};
        if (data['data'] != null) {
          for (var item in data['data']) {
            notesMap[item['date']] = true;
          }
        }
        return {'success': true, 'notes': notesMap};
      }
      return {'success': true, 'notes': {}};
    } catch (e) {
      _log('❌ Error getting notes for month: $e');
      return {'success': true, 'notes': {}};
    }
  }
}