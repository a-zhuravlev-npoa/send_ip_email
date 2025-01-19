// Пример выполнения фоновой задачи

import 'dart:async';

import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundService2 {
  static Future<void> initialize() async {
    // Запрашиваем разрешение на фоновое выполнение
    await _requestPermissions();

    // Проверяем разрешения
    final status = await FlutterBackground.hasPermissions;
    if (!status) return; // Если разрешения нет, выход

    // Конфигурируем фоновые задачи
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Фоновая задача',
      notificationText: 'Запущено выполнение фоновой задачи.',
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    // Инициализация плагина
    await FlutterBackground.initialize(androidConfig: androidConfig);

    // Включаем фоновые задачи
    FlutterBackground.enableBackgroundExecution();
    _startTimer();
  }

  static Future<void> _requestPermissions() async {
    // Запрашиваем необходимые разрешения
    if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
      // Разрешение получено
      print("test");
    }
  }

  static void _startTimer() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      print('Фоновая задача выполняется: ${DateTime.now()}');
    });
  }
}
