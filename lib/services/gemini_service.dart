// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta";
  static const String _model = "gemini-2.5-flash"; // model stabil

  // Kirim pesan dengan history (konteks percakapan)
  Future<String> sendMessageWithHistory(
    String userMessage,
    List<Map<String, String>> history,
  ) async {
    try {
      final url = Uri.parse("$_baseUrl/models/$_model:generateContent?key=$_apiKey");
      
      final List<Map<String, dynamic>> contents = [];
      // Ambil maksimal 10 pesan terakhir (hemat token)
      final startIdx = history.length > 10 ? history.length - 10 : 0;
      for (int i = startIdx; i < history.length; i++) {
        final msg = history[i];
        contents.add({
          "role": msg['role'] == 'user' ? 'user' : 'model',
          "parts": [{"text": msg['content']}]
        });
      }
      // Tambahkan pesan user saat ini
      contents.add({
        "role": "user",
        "parts": [{"text": userMessage}]
      });
      
      final requestBody = {
        "contents": contents,
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 2048, // jawaban lebih panjang
          "topP": 0.95,
        }
      };
      
      if (kDebugMode) {
        print("📤 Sending to Gemini with ${contents.length} messages");
      }
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }
        return "Maaf, saya tidak bisa memproses permintaan Anda.";
      } else if (response.statusCode == 429) {
        return "📊 Mirai sedang sibuk, coba lagi nanti ya.";
      } else {
        if (kDebugMode) print("❌ Error ${response.statusCode}: ${response.body}");
        return "Maaf, terjadi kesalahan. Silakan coba lagi.";
      }
    } catch (e) {
      if (kDebugMode) print("❌ Exception: $e");
      return "Maaf, saya sedang offline. Periksa koneksi internet Anda.";
    }
  }
}