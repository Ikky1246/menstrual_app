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

    try {
      final result = await AuthService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyOtpScreen(
                email: _emailController.text.trim(),
                resetToken: result['reset_token'] ?? '',
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
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // Header Icon
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 35,
                          color: Colors.pink.shade400,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        'Masukkan email yang terdaftar, kami akan mengirimkan kode OTP untuk mereset password Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan email terdaftar',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.pink.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.pink.shade50,
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
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Kirim Kode OTP Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Kirim Kode OTP',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ingat password? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Help Section
                      Column(
                        children: [
                          Text(
                            'Butuh bantuan?',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tim dukungan MIRAI tersedia 24/7 untuk membantu pemulihan akun',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
