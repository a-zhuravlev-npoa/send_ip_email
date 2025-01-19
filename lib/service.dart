// Пробный вариант

import 'dart:async';

import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class BackgroundService {
  static FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Инициализация уведомлений
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Конфигурируем фоновые задачи
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Фоновая задача',
      notificationText: 'Запущено выполнение фоновой задачи.',
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    // Инициализация плагина для фоновых задач
    await FlutterBackground.initialize(androidConfig: androidConfig);
  }

  static Future<void> start() async {
    // Запрашиваем разрешение на фоновое выполнение
    await _requestPermissions();

    // Проверяем разрешения
    final status = await FlutterBackground.hasPermissions;
    if (!status) return; // Если разрешения нет, выход

    // Включаем фоновые задачи
    FlutterBackground.enableBackgroundExecution();

    // Запускаем сервис для отправки HTTP-запросов
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      0,
      sendHttpRequest,
    );

    print("Background service started");
  }

  static Future<void> _requestPermissions() async {
    // Запрашиваем необходимые разрешения
    if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
      print("Разрешение на фоновое выполнение получено");
    }
  }

  static Future<void> sendHttpRequest() async {
    final prefs = await SharedPreferences.getInstance();
    bool appRun = prefs.getBool('appRun') ?? true;

    if (appRun) {
      String urlString = "http://mail.him-met.ru:83/set-ip/";
      try {
        final response = await http.get(Uri.parse(urlString));
        if (response.statusCode == 200) {
          await sendNotification(); // Отправка уведомления
          print("Запрос успешен: ${response.body}");
        } else {
          print("Ошибка: ${response.statusCode}");
        }
      } catch (e) {
        print("Ошибка при отправке запроса: $e");
      }
    }
  }

  static Future<void> sendNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails('your_channel_id', 'your_channel_name',
        channelDescription: 'your_channel_description',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false);

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
        0, 'Hello!', 'This is a background notification.', platformChannelSpecifics);
  }

  static Future<void> stop() async {
    await AndroidAlarmManager.cancel(0);
    print("Background service stopped");
  }
}
