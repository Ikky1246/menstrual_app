import 'package:flutter/material.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/screens/auth/verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.forgotPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        // Navigate ke halaman verifikasi OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              email: _emailController.text.trim(),
              resetToken: result['reset_token'],
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Lupa Password'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 50,
                    color: Colors.pink.shade400,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'Masukkan email yang terdaftar, kami akan mengirimkan kode OTP untuk mereset password Anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'masukkan email terdaftar',
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.pink.shade300),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.pink.shade300, width: 2),
                        ),
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
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                                'Kirim Kode OTP',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ingat password? ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}