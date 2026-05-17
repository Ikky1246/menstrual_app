import 'dart:async';
import 'package:flutter/material.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/screens/auth/reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String resetToken;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String _errorMessage = '';
  int _resendCountdown = 56;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else if (mounted && _resendCountdown == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {
      _errorMessage = '';
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Masukkan 6 digit kode OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.verifyResetOtp(
        email: widget.email,
        otp: _otpCode,
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                email: widget.email,
                resetToken: result['reset_token'],
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = result['message'];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
      _canResend = false;
      _resendCountdown = 56;
    });

    try {
      final result = await AuthService.forgotPassword(email: widget.email);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode OTP baru telah dikirim'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          _startCountdown();
        } else {
          setState(() {
            _canResend = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ulang kode. Coba lagi nanti.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
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
            padding: const EdgeInsets.all(20),
            child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Header Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 35,
                        color: Colors.pink.shade400,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Verifikasi Email Anda',
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
                      'Kami telah mengirimkan kode verifikasi ke ${widget.email}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 50,
                          height: 55,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: index == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
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
                              filled: true,
                              fillColor: Colors.pink.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) => _onOtpChanged(index, value),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isVerifying || _isResending)
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verifikasi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend OTP Section
                    Column(
                      children: [
                        Text(
                          'Belum menerima kode?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_isResending)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pink,
                            ),
                          )
                        else if (!_canResend)
                          Text(
                            'Kirim ulang dalam ${_resendCountdown}s',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Kirim ulang',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
