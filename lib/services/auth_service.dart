import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  // Ganti dengan URL Laravel Anda
  static const String baseUrl = "http://localhost:8000/api"; // Sesuaikan dengan IP/domain
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Mencoba login ke: $baseUrl/login'); // Untuk debug
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token dan user data
        await _saveUserData(data);
        return {
          'success': true, 
          'data': data,
          'message': 'Login berhasil'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Email atau password salah'
        };
      }
    } catch (e) {
      print('Error login: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Pastikan Laravel berjalan di $baseUrl'
      };
    }
  }

  // REGISTER
 static Future<Map<String, dynamic>> register({
  required String name,
  required String email,
  required String password,
}) async {
  try {
    print('🌐 Mengirim request ke: $baseUrl/register');
    
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password, // Penting untuk Laravel
      }),
    ).timeout(const Duration(seconds: 10));

    print('📊 Status code: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return {
        'success': true, 
        'data': data,
        'message': data['message'] ?? 'Registrasi berhasil'
      };
    } else {
      // Parse error dari Laravel
      String errorMessage = 'Registrasi gagal';
      
      if (data['errors'] != null) {
        // Validation errors
        final errors = data['errors'] as Map;
        if (errors.containsKey('email')) {
          errorMessage = errors['email'][0];
        } else if (errors.containsKey('name')) {
          errorMessage = errors['name'][0];
        } else if (errors.containsKey('password')) {
          errorMessage = errors['password'][0];
        }
      } else if (data['message'] != null) {
        errorMessage = data['message'];
      }
      
      return {
        'success': false,
        'message': errorMessage
      };
    }
  } catch (e) {
    print('💥 Connection error: $e');
    return {
      'success': false,
      'message': 'Gagal terhubung ke server. Pastikan Laravel berjalan di $baseUrl'
    };
  }
}

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    try {
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      }
    } catch (e) {
      print('Error logout: $e');
    } finally {
      // Hapus data lokal
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  // GET CURRENT USER
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      }
    } catch (e) {
      print('Error get user: $e');
    }
    
    return null;
  }

  // CEK LOGIN STATUS
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    
    if (token == null) return false;
    
    // Optional: verify token dengan backend
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return true; // Assume token valid if can't verify
    }
  }

  // GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // SAVE USER DATA
  static Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Laravel biasanya mengembalikan token di data['token']
    if (data.containsKey('token')) {
      await prefs.setString(_tokenKey, data['token']);
    } else if (data.containsKey('access_token')) {
      await prefs.setString(_tokenKey, data['access_token']);
    }
    
    // Simpan user data
    if (data.containsKey('user')) {
      await prefs.setString(_userKey, jsonEncode(data['user']));
    } else {
      // Jika user data ada di root
      await prefs.setString(_userKey, jsonEncode(data));
    }
  }

  // UPDATE PROFILE
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    String? password,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final Map<String, dynamic> data = {'name': name};
      if (email != null) data['email'] = email;
      if (password != null) {
        data['password'] = password;
        data['password_confirmation'] = password;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(responseData['user'] ?? responseData));
        
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update profil'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}