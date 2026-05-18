import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8E8F0), // Soft pink background
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Tandai semua dibaca
            },
            child: const Text(
              'Tanda semua dibaca',
              style: TextStyle(color: Colors.pink),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HARI INI
          const Text(
            'HARI INI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          _buildNotificationCard(
            icon: Icons.calendar_today,
            iconColor: Colors.pink,
            title: 'Prediksi Siklus',
            subtitle:
                'Siklus haid Anda diprediksi akan dimulai dalam 2 hari. Siapkan diri Anda!',
            time: 'Baru saja',
            hasDot: true,
          ),

          const SizedBox(height: 12),

          _buildNotificationCard(
            icon: Icons.female,
            iconColor: Colors.pink,
            title: 'Tips Kesehatan',
            subtitle:
                'Minum air putih yang cukup membantu mengurangi kram perut saat haid.',
            time: '2 jam lalu',
          ),

          const SizedBox(height: 24),

          // MINGGU INI
          const Text(
            'MINGGU INI',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          _buildNotificationCard(
            icon: Icons.system_update,
            iconColor: Colors.grey,
            title: 'Pembaruan Sistem',
            subtitle:
                'Versi terbaru MIRAI tersedia. Perbarui sekarang untuk fitur lebih lengkap!',
            time: 'Kemarin',
            actionText: 'Perbarui Sekarang',
          ),

          const SizedBox(height: 12),

          _buildNotificationCard(
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Hidrasi',
            subtitle:
                'Jangan lupa untuk mencatat asupan air harian Anda untuk menjaga keseimbangan hormon.',
            time: '3 hari lalu',
          ),

          const SizedBox(height: 12),

          _buildNotificationCard(
            icon: Icons.group,
            iconColor: Colors.purple,
            title: 'Komunitas',
            subtitle:
                'Diskusi baru dimulai di grup "Wellness Routine". Mari bergabung!',
            time: '5 hari lalu',
          ),

          const SizedBox(height: 32),

          // Bottom Motivational Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Placeholder Image (bisa diganti dengan AssetImage nanti)
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_florist,
                      size: 80,
                      color: Colors.pink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Anda Teratur!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Semua notifikasi penting telah Anda tinjau. Tetap jaga kesehatan Anda hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    String? actionText,
    bool hasDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (hasDot) ...[
                      const SizedBox(width: 6),
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.red,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (actionText != null)
                      GestureDetector(
                        onTap: () {
                          // TODO: Action button
                        },
                        child: Text(
                          actionText,
                          style: const TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
