// lib/screens/profile_screen.dart
// REDESIGNED UI - Mengikuti desain MIRAI Profil dari HTML
// Logika tetap sama, hanya tampilan yang diubah
// FIX: Tombol "PERBARUI DATA TAMBAHAN" sekarang berfungsi mengarah ke OptionalFormScreen
// ADD: Cek apakah data tambahan sudah lengkap atau belum

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/cycle_service.dart';
import '../screens/onboarding/optional_form_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDataLengkap = false; // Apakah data tambahan sudah lengkap?

  final Color primary = const Color(0xFFEC1E63);
  final Color primaryLight = const Color(0xFFFFD3E0);
  final Color surface = const Color(0xFFFFF8F7);
  final Color onSurface = const Color(0xFF281719);
  final Color onSurfaceVariant = const Color(0xFF5C3F43);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();

      if (user != null) {
        setState(() {
          _nameController.text = user.name?.trim() ?? '';
          _emailController.text = user.email?.trim() ?? '';
          _phoneController.text = user.noTelepon?.trim() ?? '';
          _ageController.text = user.age?.toString() ?? '';
          // Cek apakah data tambahan sudah lengkap
          _isDataLengkap = user.age != null && user.pcosDiagnosed != null && user.birthControlUse != null;
        });
      } else {
        final result = await AuthService.getProfile();
        if (result['success'] == true && result['user'] != null) {
          final u = result['user'];
          setState(() {
            _nameController.text = u.name?.trim() ?? '';
            _emailController.text = u.email?.trim() ?? '';
            _phoneController.text = u.noTelepon?.trim() ?? '';
            _ageController.text = u.age?.toString() ?? '';
            _isDataLengkap = u.age != null && u.pcosDiagnosed != null && u.birthControlUse != null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data profil')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final result = await AuthService.updateProfile(
        namaLengkap: _nameController.text.trim(),
        noTelepon: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui ✅'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload profil untuk update status data tambahan
          _loadUserProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(color: Color(0xFFEC1E63))),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF5C3F43)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AuthService.logout();
    } catch (e) {
      // ignore
    }

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // ==================== NAVIGASI KE OPTIONAL FORM (DENGAN DATA SIKLUS TERBARU) ====================
  Future<void> _navigateToOptionalForm() async {
    // Ambil siklus terakhir dari server
    final cycleResult = await CycleService.getLatestCycle();
    if (!mounted) return;

    if (!cycleResult['success'] || cycleResult['cycle'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data siklus. Silakan isi data mandatory terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cycle = cycleResult['cycle'];

    // Ambil period duration dari SharedPreferences (default 7)
    final prefs = await SharedPreferences.getInstance();
    final periodDuration = prefs.getInt('period_duration') ?? 7;

    // Jika data tambahan sudah lengkap, tampilkan konfirmasi "Perbarui" atau langsung arahkan
    // Kita akan tetap arahkan ke OptionalFormScreen, karena user bisa mengubah data.

    // Navigasi ke OptionalFormScreen dengan parameter yang valid
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionalFormScreen(
          cycleId: cycle.id!,
          lastPeriodDate: cycle.lastPeriodDate,
          previousPeriodDate: cycle.previousPeriodDate,
          cycleLengthDays: cycle.cycleLengthDays ?? 28,
          periodDurationDays: periodDuration,
          painLevel: cycle.painLevel ?? 5,
          stressLevel: cycle.stressScoreCycle ?? 4,
          sleepHours: cycle.sleepHoursCycle ?? 7,
          moodLevel: cycle.moodScore ?? 7,
        ),
      ),
    );

    // Jika user kembali dari OptionalForm (misal menekan back), reload profil
    if (result == true) {
      _loadUserProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryLight.withOpacity(0.6),
              surface.withOpacity(0.3),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Sakura Petals Background
            ..._buildSakuraDecorations(),

            // Main Content
            Column(
              children: [
                // ===== GLASS TOP APP BAR =====
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.6)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: primary,
                            size: 26,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Text(
                        'Profil Saya',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          fontFamily: 'PlusJakartaSans',
                        ),
                      ),
                      const Spacer(),
                      // Logout Button
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.logout, color: primary, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== BODY CONTENT =====
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFEC1E63),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),

                                // ===== PROFILE PICTURE =====
                                _buildProfilePicture(),

                                const SizedBox(height: 12),

                                // Username
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : 'Nama Pengguna',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: onSurface,
                                    fontFamily: 'PlusJakartaSans',
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // ===== FORM SECTION =====
                                _buildGlassCard(
                                  child: Column(
                                    children: [
                                      // Nama
                                      _buildFloatingLabelField(
                                        label: 'NAMA',
                                        controller: _nameController,
                                        icon: Icons.person,
                                        hint: 'Nama lengkap',
                                      ),
                                      const SizedBox(height: 20),

                                      // Email
                                      _buildFloatingLabelField(
                                        label: 'EMAIL',
                                        controller: _emailController,
                                        icon: Icons.email,
                                        hint: 'email@example.com',
                                        enabled: false,
                                      ),
                                      const SizedBox(height: 20),

                                      // No Telepon
                                      _buildFloatingLabelField(
                                        label: 'NO. TELEPON',
                                        controller: _phoneController,
                                        icon: Icons.phone,
                                        hint: '08xx-xxxx-xxxx',
                                      ),
                                      const SizedBox(height: 20),

                                      // Usia
                                      _buildFloatingLabelField(
                                        label: 'USIA',
                                        controller: _ageController,
                                        icon: Icons.cake,
                                        hint: '21',
                                        isNumber: true,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ===== SAVE BUTTON =====
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 8,
                                      shadowColor: primary.withOpacity(0.3),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Simpan Perubahan',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                              fontFamily: 'PlusJakartaSans',
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ===== ADDITIONAL DATA CARD =====
                                _buildGlassCard(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: primaryLight.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: primary.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _isDataLengkap
                                                  ? '✅ Data tambahan sudah lengkap'
                                                  : '⚠️ Data tambahan belum lengkap',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: _isDataLengkap
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                                fontFamily: 'PlusJakartaSans',
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _isDataLengkap
                                                  ? 'Klik tombol di bawah untuk memperbarui data tambahan Anda.'
                                                  : 'Lengkapi data tambahan Anda untuk mendapatkan prediksi siklus kesehatan yang lebih akurat dan personal.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: onSurface,
                                                fontFamily: 'PlusJakartaSans',
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _navigateToOptionalForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            elevation: 6,
                                            shadowColor: primary.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                          child: Text(
                                            _isDataLengkap
                                                ? 'PERBARUI DATA TAMBAHAN'
                                                : 'LENGKAPI DATA TAMBAHAN',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1,
                                              fontFamily: 'PlusJakartaSans',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== PROFILE PICTURE =====
  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 144,
          height: 144,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC1E63), Color(0xFFFF85A2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Icon(Icons.person, size: 70, color: primary),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC1E63), Color(0xFFFF85A2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.edit, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ===== GLASS CARD =====
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  // ===== FLOATING LABEL FIELD =====
  Widget _buildFloatingLabelField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isNumber = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(0.05), blurRadius: 4),
            ],
            border: Border.all(color: primary.withOpacity(0.1), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: primary,
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryLight.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(0.02), blurRadius: 8),
            ],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: onSurface,
              fontFamily: 'PlusJakartaSans',
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primary, size: 22),
              hintText: hint,
              hintStyle: TextStyle(
                color: onSurfaceVariant.withOpacity(0.5),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabled: enabled,
            ),
            validator: (value) {
              if (label == 'NAMA' && (value == null || value.trim().isEmpty)) {
                return 'Nama tidak boleh kosong';
              }
              if (label == 'NO. TELEPON' && value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return 'Nomor telepon terlalu pendek';
                }
              }
              if (label == 'USIA' && value != null && value.isNotEmpty) {
                final age = int.tryParse(value);
                if (age == null || age < 10 || age > 100) {
                  return 'Usia harus antara 10-100';
                }
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  // ===== SAKURA DECORATIONS =====
  List<Widget> _buildSakuraDecorations() {
    return [
      // Petal 1
      Positioned(
        top: 120,
        left: -30,
        child: Transform.rotate(
          angle: 0.8,
          child: Icon(
            Icons.favorite,
            color: primaryLight.withOpacity(0.25),
            size: 100,
          ),
        ),
      ),
      // Petal 2
      Positioned(
        bottom: 250,
        right: -30,
        child: Transform.rotate(
          angle: -0.5,
          child: Icon(
            Icons.favorite,
            color: primaryLight.withOpacity(0.2),
            size: 80,
          ),
        ),
      ),
      // Blur Circle 1
      Positioned(
        top: 60,
        left: -40,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.15),
            borderRadius: BorderRadius.circular(120),
          ),
        ),
      ),
      // Blur Circle 2
      Positioned(
        bottom: 180,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: primaryLight.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    ];
  }
}