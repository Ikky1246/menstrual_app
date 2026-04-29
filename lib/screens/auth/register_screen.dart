import 'package:flutter/material.dart';
import 'package:menstrual_app/screens/auth/login_screen.dart';
import 'package:menstrual_app/screens/auth/verify_email_screen.dart';
import 'package:menstrual_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap setujui syarat dan ketentuan'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        print('📝 Mencoba register dengan:');
        print('Name: ${_nameController.text}');
        print('Email: ${_emailController.text}');
        print('Password: ${_passwordController.text}');
        
        final result = await AuthService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        print('📥 Response dari server: $result');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success']) {
            // Navigasi ke halaman verifikasi OTP
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyEmailScreen(
                  email: _emailController.text.trim(),
                  verificationToken: result['verification_token'],
                ),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Registrasi berhasil! Silakan verifikasi email Anda. 💕'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Tampilkan error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        print('🔥 Error: $e');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            colors: [
              Colors.pink.shade50,
              Colors.white,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Back button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.pink.shade700,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Judul
                  const Text(
                    'Buat Akun\nBaru',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Nama Lengkap
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap',
                            hintText: 'masukkan nama kamu',
                            prefixIcon: Icon(Icons.person_outline, color: Colors.pink.shade300),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'masukkan email kamu',
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.pink.shade300),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'minimal 6 karakter',
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.pink.shade300),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
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
                        
                        const SizedBox(height: 16),
                        
                        // Konfirmasi Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            hintText: 'masukkan ulang password',
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.pink.shade300),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.pink.shade300,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.pink.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Terms & Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeTerms = value ?? false;
                                });
                              },
                              activeColor: Colors.pink,
                            ),
                            Expanded(
                              child: Text(
                                'Saya setuju dengan Syarat & Ketentuan dan Kebijakan Privasi',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Daftar',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login disini',
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