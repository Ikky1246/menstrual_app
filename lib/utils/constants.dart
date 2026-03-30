import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.pink;
  static const Color primaryLight = Color(0xFFFFF0F6);
  static const Color primaryDark = Color(0xFFC2185B);
  
  static const Color secondary = Color(0xFF9C27B0);
  static const Color accent = Color(0xFFFF4081);
  
  static const Color menstruation = Colors.red;
  static const Color prediction = Color(0xFFFF80AB);
  static const Color ovulation = Color(0xFF9C27B0);
  static const Color fertile = Color(0xFF2196F3);
  
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  static const Color background = Color(0xFFFFF5F9);
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
}

class AppStrings {
  // App Title
  static const String appName = 'Siklusku';
  static const String appTagline = 'Catatan Siklus Haidmu';
  
  // Auth
  static const String login = 'Masuk';
  static const String register = 'Daftar';
  static const String logout = 'Keluar';
  static const String email = 'Email';
  static const String password = 'Kata Sandi';
  static const String confirmPassword = 'Konfirmasi Kata Sandi';
  static const String forgotPassword = 'Lupa Kata Sandi?';
  static const String noAccount = 'Belum punya akun?';
  static const String haveAccount = 'Sudah punya akun?';
  
  // Onboarding
  static const String mandatoryData = 'Data Wajib';
  static const String optionalData = 'Data Tambahan';
  static const String lastPeriod = 'Tanggal Haid Terakhir';
  static const String previousPeriod = 'Tanggal Haid Sebelumnya';
  static const String cycleLength = 'Panjang Siklus';
  static const String periodDuration = 'Lama Haid';
  static const String stressLevel = 'Tingkat Stres';
  static const String sleepHours = 'Jam Tidur';
  static const String healthScore = 'Skor Kesehatan';
  
  // Dashboard
  static const String myCycle = 'Siklusku';
  static const String prediction = 'Prediksi';
  static const String history = 'Riwayat';
  static const String profile = 'Profil';
  static const String settings = 'Pengaturan';
  
  // Messages
  static const String welcome = 'Selamat Datang';
  static const String success = 'Berhasil!';
  static const String error = 'Terjadi Kesalahan';
  static const String loading = 'Memuat...';
  static const String empty = 'Tidak ada data';
  static const String confirm = 'Konfirmasi';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String skip = 'Lewati';
}

class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String splash = 'assets/images/splash.png';
  static const String onboarding1 = 'assets/images/onboarding1.png';
  static const String onboarding2 = 'assets/images/onboarding2.png';
  static const String onboarding3 = 'assets/images/onboarding3.png';
}

class AppDurations {
  static const Duration splash = Duration(seconds: 2);
  static const Duration animation = Duration(milliseconds: 300);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration apiTimeout = Duration(seconds: 10);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppFontSize {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double display = 24.0;
}

class AppTextStyle {
  static const TextStyle heading1 = TextStyle(
    fontSize: AppFontSize.display,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: AppFontSize.xxl,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: AppFontSize.xl,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: AppFontSize.md,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: AppFontSize.sm,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: AppFontSize.xs,
    color: AppColors.textHint,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class AppConstants {
  // Cycle related
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int minPeriodDuration = 2;
  static const int maxPeriodDuration = 10;
  
  // Date format
  static const String dateFormatDisplay = 'dd MMMM yyyy';
  static const String dateFormatApi = 'yyyy-MM-dd';
  static const String dateFormatMonth = 'MMMM yyyy';
  
  // Storage keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'user_data';
  static const String keyCycleData = 'cycle_data';
  static const String keyTheme = 'theme_mode';
  static const String keyNotifications = 'notifications_enabled';
  
  // API Endpoints
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const String apiLogin = '/login';
  static const String apiRegister = '/register';
  static const String apiLogout = '/logout';
  static const String apiUser = '/user';
  static const String apiPredict = '/predict';
  static const String apiCycle = '/cycle';
  static const String apiHistory = '/history';
}

class AppValidation {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? validateNumber(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Field tidak boleh kosong';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Masukkan angka yang valid';
    }
    if (min != null && number < min) {
      return 'Nilai minimal $min';
    }
    if (max != null && number > max) {
      return 'Nilai maksimal $max';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field wajib diisi';
    }
    return null;
  }
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String prediction = '/prediction';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String history = '/history';
}