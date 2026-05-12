// lib/services/notification_service.dart
// Service untuk notifikasi lokal

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // ============================================
  // INISIALISASI NOTIFIKASI
  // ============================================
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();
    
    // Konfigurasi untuk Android
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Konfigurasi untuk iOS
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
    
    // Request izin untuk Android (API 33+)
    await _requestPermissions();
    
    _isInitialized = true;
  }

  static Future<void> _requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // ============================================
  // TAMPILKAN NOTIFIKASI SEGERA
  // ============================================
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'menstrual_channel',
      'Siklusku Notifications',
      channelDescription: 'Notifikasi untuk pengingat siklus haid',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
  }

  // ============================================
  // JADWALKAN NOTIFIKASI
  // ============================================
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'menstrual_channel',
      'Siklusku Notifications',
      channelDescription: 'Notifikasi untuk pengingat siklus haid',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ============================================
  // SCHEDULE PENGINGAT HAID (Berdasarkan prediksi)
  // ============================================
  static Future<void> schedulePeriodReminders({
    required DateTime predictedStartDate,
    required String userToken,
  }) async {
    // Hapus notifikasi lama
    await cancelAllNotifications();
    
    // Notifikasi 5 hari sebelum haid
    final fiveDaysBefore = predictedStartDate.subtract(const Duration(days: 5));
    if (fiveDaysBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 1,
        title: '⚠️ Pengingat Haid',
        body: 'Haid diperkirakan akan datang dalam 5 hari lagi. Siapkan diri Anda!',
        scheduledDate: fiveDaysBefore,
        payload: 'period_prediction',
      );
    }
    
    // Notifikasi 3 hari sebelum haid
    final threeDaysBefore = predictedStartDate.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 2,
        title: '⚠️ Pengingat Haid',
        body: 'Haid diperkirakan akan datang dalam 3 hari lagi. Jangan lupa siapkan perlengkapan!',
        scheduledDate: threeDaysBefore,
        payload: 'period_prediction',
      );
    }
    
    // Notifikasi 1 hari sebelum haid
    final oneDayBefore = predictedStartDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 3,
        title: '⚠️ Pengingat Haid',
        body: 'Haid diperkirakan akan datang BESOK!',
        scheduledDate: oneDayBefore,
        payload: 'period_prediction',
      );
    }
    
    // Notifikasi hari haid
    await scheduleNotification(
      id: 4,
      title: '📅 Hari Pertama Haid',
      body: 'Hari ini adalah perkiraan hari pertama haid Anda. Catat di aplikasi!',
      scheduledDate: predictedStartDate,
      payload: 'period_start',
    );
  }

  // ============================================
  // SCHEDULE PENGINGAT OVULASI
  // ============================================
  static Future<void> scheduleOvulationReminder({
    required DateTime ovulationDate,
  }) async {
    if (ovulationDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 5,
        title: '🥚 Masa Ovulasi',
        body: 'Hari ini adalah perkiraan masa ovulasi Anda. Masa subur!',
        scheduledDate: ovulationDate,
        payload: 'ovulation',
      );
    }
  }

  // ============================================
  // SCHEDULE PENGINGAT CATATAN HARIAN
  // ============================================
  static Future<void> scheduleDailyNoteReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('daily_note_reminder') ?? true;
    
    if (!isEnabled) return;
    
    final now = DateTime.now();
    final reminderTime = DateTime(
      now.year,
      now.month,
      now.day,
      20, // 20:00 = 8 PM
      0,
    );
    
    if (reminderTime.isAfter(now)) {
      await scheduleNotification(
        id: 6,
        title: '📝 Catatan Harian',
        body: 'Jangan lupa catat mood dan gejala Anda hari ini!',
        scheduledDate: reminderTime,
        payload: 'daily_note',
      );
    }
  }

  // ============================================
  // SCHEDULE PENGINGAT KOREKSI (3 hari setelah prediksi)
  // ============================================
  static Future<void> scheduleCorrectionReminder({
    required DateTime predictedStartDate,
  }) async {
    final correctionReminderDate = predictedStartDate.add(const Duration(days: 3));
    
    if (correctionReminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 7,
        title: '📊 Konfirmasi Siklus',
        body: 'Apakah haid Anda sudah sesuai prediksi? Bantu AI belajar dengan mengkonfirmasi!',
        scheduledDate: correctionReminderDate,
        payload: 'correction',
      );
    }
  }

  // ============================================
  // BATALKAN SEMUA NOTIFIKASI
  // ============================================
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ============================================
  // BATALKAN NOTIFIKASI BERDASARKAN ID
  // ============================================
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ============================================
  // SCHEDULE BERDASARKAN DATA USER
  // ============================================
  static Future<void> scheduleAllReminders({
    required DateTime predictedStartDate,
    required DateTime ovulationDate,
    required String userToken,
  }) async {
    await initialize();
    
    // Hapus notifikasi lama
    await cancelAllNotifications();
    
    // Schedule semua pengingat
    await schedulePeriodReminders(
      predictedStartDate: predictedStartDate,
      userToken: userToken,
    );
    
    await scheduleOvulationReminder(ovulationDate: ovulationDate);
    await scheduleDailyNoteReminder();
    await scheduleCorrectionReminder(predictedStartDate: predictedStartDate);
  }
}