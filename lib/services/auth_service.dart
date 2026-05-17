import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  // ==============================================
  // LOGIN - untuk USER (mobile)
  // ==============================================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print(
        '🔐 Mencoba login user ke: ${AppConstants.baseUrl}/api/mobile/login',
      );

      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/login'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppDurations.apiTimeout);

      print('📊 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        final token = data['data']['token'];

        final user = User.fromJson(userData);

        await _saveUserData(user, token);

        // Simpan email dan password untuk refresh token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        await prefs.setString('user_password', password);
        print('✅ Email dan password disimpan untuk refresh token');

        return {
          'success': true,
          'user': user,
          'token': token,
          'message': data['message'] ?? 'Login berhasil',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email atau password salah',
        };
      }
    } catch (e) {
      print('❌ Error login: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Pastikan Laravel berjalan',
      };
    }
  }

  // ==============================================
  // REGISTER - untuk USER (mobile) dengan OTP
  // ==============================================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print(
        '🌐 Mengirim request register ke: ${AppConstants.baseUrl}/api/mobile/register',
      );

      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/register'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(AppDurations.apiTimeout);

      print('📊 Status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'verification_token': data['data']['verification_token'] ?? '',
          'user': data['data']['user'],
        };
      } else {
        String errorMessage = data['message'] ?? 'Registrasi gagal';

        if (data['errors'] != null) {
          final errors = data['errors'] as Map;
          if (errors.containsKey('email')) {
            errorMessage = errors['email'][0];
          } else if (errors.containsKey('name')) {
            errorMessage = errors['name'][0];
          } else if (errors.containsKey('password')) {
            errorMessage = errors['password'][0];
          }
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('💥 Connection error: $e');
      return {
        'success': false,
        'message': 'Gagal terhubung ke server. Pastikan Laravel berjalan',
      };
    }
  }

  // ==============================================
  // VERIFY OTP (setelah register)
  // ==============================================
  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
    String? password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/verify-otp'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        final token = data['data']['token'];

        final user = User.fromJson(userData);
        await _saveUserData(user, token);

        if (password != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', email);
          await prefs.setString('user_password', password);
          print('✅ Email dan password disimpan untuk refresh token');
        }

        return {
          'success': true,
          'message': data['message'],
          'user': user,
          'token': token,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Verifikasi gagal',
        };
      }
    } catch (e) {
      print('❌ Verify Email OTP error: $e');
      return {'success': false, 'message': 'Gagal verifikasi OTP'};
    }
  }

  // ==============================================
  // RESEND OTP
  // ==============================================
  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/resend-otp'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email}),
          )
          .timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'verification_token': data['data']['verification_token'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim ulang OTP',
        };
      }
    } catch (e) {
      print('❌ Resend OTP error: $e');
      return {'success': false, 'message': 'Gagal mengirim ulang OTP'};
    }
  }

  // ==============================================
  // LOGOUT
  // ==============================================
  static Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);

    try {
      if (token != null) {
        print('🚪 Logout user dari: ${AppConstants.baseUrl}/api/mobile/logout');

        await http
            .post(
              Uri.parse('${AppConstants.baseUrl}/api/mobile/logout'),
              headers: {
                "Content-Type": "application/json",
                "Accept": "application/json",
                "Authorization": "Bearer $token",
              },
            )
            .timeout(AppDurations.apiTimeout);
      }
    } catch (e) {
      print('❌ Error logout: $e');
    } finally {
      await _clearUserData();
    }

    return {'success': true, 'message': 'Logout berhasil'};
  }

  // ==============================================
  // GET CURRENT USER
  // ==============================================
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.keyUser);

    if (userJson == null) return null;

    try {
      final userMap = jsonDecode(userJson);
      return User.fromMap(userMap);
    } catch (e) {
      print('❌ Error parsing user data: $e');
      return null;
    }
  }

  // ==============================================
  // GET PROFILE FROM SERVER
  // ==============================================
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final response = await http
          .get(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/user/profile'),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(AppDurations.apiTimeout);

      print('📊 Profile response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final userData = data['data']['user'];
          final token = await getToken();
          final user = User.fromJson(userData);
          await _saveUserData(user, token!);

          return {
            'success': true,
            'user': user,
            'message': 'Berhasil mengambil profil',
          };
        }
      }

      return {'success': false, 'message': 'Gagal mengambil profil'};
    } catch (e) {
      print('❌ Error get profile: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // UPDATE PROFILE
  // ==============================================
  static Future<Map<String, dynamic>> updateProfile({
    String? namaLengkap,
    String? noTelepon,
    int? age,
    double? weightKg,
    double? heightCm,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final Map<String, dynamic> payload = {};
      if (namaLengkap != null) payload['nama_lengkap'] = namaLengkap;
      if (noTelepon != null) payload['no_telepon'] = noTelepon;
      if (age != null) payload['age'] = age;
      if (weightKg != null) payload['weight_kg'] = weightKg;
      if (heightCm != null) payload['height_cm'] = heightCm;

      final response = await http
          .put(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/user/profile'),
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(payload),
          )
          .timeout(AppDurations.apiTimeout);

      final responseData = jsonDecode(response.body);
      print('📊 Update response: ${response.statusCode}');

      if (response.statusCode == 200 && responseData['success'] == true) {
        await getProfile();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile berhasil diupdate',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update profil',
        };
      }
    } catch (e) {
      print('❌ Error update profile: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==============================================
  // FORGOT PASSWORD - Send OTP
  // ==============================================
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/forgot-password'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email}),
          )
          .timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'reset_token': data['data']['token'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim kode OTP',
        };
      }
    } catch (e) {
      print('❌ Forgot password error: $e');
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // ==============================================
  // VERIFY OTP FOR RESET PASSWORD
  // ==============================================
  static Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/verify-otp-reset'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({'email': email, 'otp': otp}),
          )
          .timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'reset_token': data['data']['reset_token'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Kode OTP tidak valid',
        };
      }
    } catch (e) {
      print('❌ Verify reset OTP error: $e');
      return {'success': false, 'message': 'Gagal verifikasi OTP'};
    }
  }

  // ==============================================
  // RESET PASSWORD
  // ==============================================
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/api/mobile/reset-password'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'email': email,
              'reset_token': resetToken,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(AppDurations.apiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mereset password',
        };
      }
    } catch (e) {
      print('❌ Reset password error: $e');
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }

  // ==============================================
  // REFRESH TOKEN
  // ==============================================
  static Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');

      if (email == null || password == null) {
        print('❌ Refresh token gagal: email/password tidak tersimpan');
        return false;
      }

      print('🔄 Mencoba refresh token untuk: $email');

      final result = await login(email: email, password: password);

      if (result['success'] == true) {
        print('✅ Refresh token berhasil!');
        return true;
      } else {
        print('❌ Refresh token gagal: ${result['message']}');
        return false;
      }
    } catch (e) {
      print('❌ Refresh token error: $e');
      return false;
    }
  }

  // ==============================================
  // CEK LOGIN STATUS
  // ==============================================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);
    return token != null && token.isNotEmpty;
  }

  // ==============================================
  // GET TOKEN
  // ==============================================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyToken);
  }

  // ==============================================
  // PRIVATE: SAVE USER DATA
  // ==============================================
  static Future<void> _saveUserData(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(AppConstants.keyToken, token);
    await prefs.setString(AppConstants.keyUser, jsonEncode(user.toMap()));

    print('✅ Token dan user data saved');
  }

  // ==============================================
  // PRIVATE: CLEAR USER DATA
  // ==============================================
  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUser);
    await prefs.remove('user_email');
    await prefs.remove('user_password');
    print('✅ User data cleared');
  }
}
