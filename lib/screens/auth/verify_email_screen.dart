import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:menstrual_app/services/auth_service.dart';
import 'package:menstrual_app/screens/onboarding/mandatory_form_screen.dart';

// SakuraColors sudah didefinisikan di login_screen.dart, dipakai ulang di sini
// supaya tidak terjadi duplikasi class saat file-file ini di-import bersamaan.
import 'package:menstrual_app/screens/auth/login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? verificationToken;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.verificationToken,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String _errorMessage = '';
  String _successMessage = '';
  int _resendCooldown = 0;
  Timer? _timer;

  // ===== LOGIKA TIDAK DIUBAH SAMA SEKALI =====
  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_resendCooldown > 0) {
          setState(() {
            _resendCooldown--;
          });
        } else {
          timer.cancel();
        }
      }
    });
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
      _successMessage = '';
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
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    final result = await AuthService.verifyEmailOtp(
      email: widget.email,
      otp: _otpCode,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MandatoryFormScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email berhasil diverifikasi! ✨'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
      _successMessage = '';
    });

    final result = await AuthService.resendOtp(email: widget.email);

    setState(() {
      _isResending = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _successMessage = 'Kode OTP baru telah dikirim ke email Anda';
        });
        _startResendCooldown();
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
      }
    }
  }
  // ===== AKHIR LOGIKA =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient sakura
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SakuraColors.light, SakuraColors.bg, Colors.white],
              ),
            ),
          ),

          // Petal-petal dekoratif (statis, meniru .sakura-petal)
          const _SakuraPetal(top: 40, left: 20, size: 48, opacity: 0.6),
          const _SakuraPetal(top: 130, right: 40, size: 64, opacity: 0.4),
          const _SakuraPetal(bottom: 160, left: 80, size: 32, opacity: 0.5),
          const _SakuraPetal(bottom: 80, right: 64, size: 56, opacity: 0.3),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon amplop
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white),
                            boxShadow: [
                              BoxShadow(
                                color: SakuraColors.primary.withOpacity(0.08),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SakuraColors.primary.withOpacity(
                                      0.2,
                                    ),
                                    width: 2,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.mail_outline,
                                size: 34,
                                color: SakuraColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Judul
                        const Text(
                          'Verifikasi Email Anda',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: SakuraColors.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subjudul dengan email ditebalkan
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'Kami telah mengirimkan kode verifikasi ke ',
                              ),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: SakuraColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chip info spam
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: SakuraColors.primary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cek folder Spam jika tidak menerima email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // OTP Input Fields — gaya pill/rounded-full sesuai desain baru
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            6,
                            (index) => _OtpBox(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              hasError: _errorMessage.isNotEmpty,
                              onChanged: (value) => _onOtpChanged(index, value),
                            ),
                          ),
                        ),

                        // Pesan error (hanya tampil kalau _errorMessage terisi)
                        if (_errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDAD6).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFBA1A1A).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFBA1A1A),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Color(0xFFBA1A1A),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Pesan sukses (hanya tampil kalau _successMessage terisi)
                        if (_successMessage.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4F5E0).withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green.shade400.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _successMessage,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        // Tombol Verifikasi (gradient)
                        _GradientButton(
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _verifyOtp,
                        ),
                        const SizedBox(height: 24),

                        // Bagian kirim ulang OTP
                        Text(
                          'Tidak menerima kode?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (_resendCooldown > 0)
                          Text(
                            'Kirim ulang dalam ${_resendCooldown}s',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _resendOtp,
                            child: _isResending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: SakuraColors.primary,
                                    ),
                                  )
                                : const Text(
                                    'Kirim ulang',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: SakuraColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),

                        const SizedBox(height: 18),
                        Container(
                          width: 48,
                          height: 1,
                          color: SakuraColors.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 18),

                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: SakuraColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
          ),
        ],
      ),
    );
  }
}

// ============ Widget-widget bantu tampilan ============

/// Kartu kaca (glassmorphism) meniru .glass-card, dengan bayangan
/// diletakkan di luar area blur supaya tetap terlihat jelas.
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: SakuraColors.primary.withOpacity(0.20),
            blurRadius: 48,
            spreadRadius: -4,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: SakuraColors.dark.withOpacity(0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Kotak input OTP tunggal, gaya pill/rounded-full meniru .otp-input pada desain baru.
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? const Color(0xFFBA1A1A)
        : SakuraColors.primary.withOpacity(0.3);

    return SizedBox(
      width: 44,
      height: 54,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasError
              ? const Color(0xFFFFDAD6).withOpacity(0.5)
              : Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: borderColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: SakuraColors.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Tombol gradient meniru tombol CTA "Verifikasi" pada desain baru.
class _GradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SakuraColors.primary, Color(0xFFFF4B82)],
          ),
          boxShadow: [
            BoxShadow(
              color: SakuraColors.primary.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Center(
              child: isLoading
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dekorasi petal sakura statis, meniru .sakura-petal / .petal
class _SakuraPetal extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final double opacity;

  const _SakuraPetal({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: 0.785398, // 45 derajat
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: SakuraColors.primary.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
