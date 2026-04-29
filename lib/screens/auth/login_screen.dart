import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/auth/register_screen.dart';
import 'package:menstrual_app/screens/dashboard_screen.dart';
import 'package:menstrual_app/screens/auth/forgot_password_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Panggil API Login
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Cek apakah user sudah punya data siklus
          // Jika belum, arahkan ke onboarding
          // Jika sudah, arahkan ke dashboard

          // Sementara langsung ke dashboard dulu
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login berhasil! 💕'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          // Tampilkan error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
            colors: [Colors.pink.shade50, Colors.white, Colors.pink.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header dengan ilustrasi
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 60,
                        color: Colors.pink.shade400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Judul
                  const Text(
                    'Selamat Datang\nKembali!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Senang melihatmu lagi. Yuk lanjutkan catatan siklusmu!',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'masukkan email kamu',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.pink.shade300,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.pink.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'masukkan password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.pink.shade300,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.pink.shade300,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Colors.pink.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        // Remember me & Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.pink,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const Text('Ingat saya'),
                              ],
                            ),
                            // Forgot password link
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Lupa password?',
                                style: TextStyle(color: Colors.pink.shade700),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar sekarang',
                          style: TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
