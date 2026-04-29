import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/auth/login_screen.dart';
import 'package:menstrual_app/screens/auth/register_screen.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/screens/onboarding/mandatory_form_screen.dart';
import 'package:menstrual_app/screens/onboarding/optional_form_screen.dart';
import 'package:menstrual_app/screens/auth/forgot_password_screen.dart';
import 'package:menstrual_app/screens/auth/verify_email_screen.dart';
import 'package:menstrual_app/screens/auth/verify_otp_screen.dart';
import 'package:menstrual_app/screens/auth/reset_password_screen.dart';
import 'package:menstrual_app/screens/prediction_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siklusku',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/mandatory': (context) => const MandatoryFormScreen(),
        // HAPUS '/optional' dari sini karena butuh parameter
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/prediction': (context) => const PredictionScreen(),
      },
      onGenerateRoute: (settings) {
        // Untuk halaman dengan parameter
        if (settings.name == '/verify-email') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerifyEmailScreen(
              email: args['email'],
              verificationToken: args['verification_token'],
            ),
          );
        }
        if (settings.name == '/verify-otp') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              email: args['email'],
              resetToken: args['reset_token'],
            ),
          );
        }
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: args['email'],
              resetToken: args['reset_token'],
            ),
          );
        }
        // OptionalFormScreen tidak pakai named route, langsung MaterialPageRoute
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = await AuthService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        final user = await AuthService.getCurrentUser();
        final hasCycleData = await _hasCycleData();

        if (hasCycleData) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/mandatory');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<bool> _hasCycleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCycle = prefs.getBool('has_cycle_data') ?? false;
      return hasCycle;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade300,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Siklusku',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Catatan Siklus Haidmu',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}