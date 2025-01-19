import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async'; // Для Timer
// import 'test.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  // await BackgroundService2.initialize();
  runApp(const MyApp()); // Запуск приложения
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App send Email',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController(text: '10'); // Значение по умолчанию 10
  final int _minValue = 10; // Минимальное значение
  int _requestInterval = 10; // Значение интервала по умолчанию
  bool _appRun = true; // Переменная для хранения состояния приложения

  final String _urlString = "http://mail.him-met.ru:83/set-ip/";
  Timer? _timer; // Описание таймера как null

  @override
  void initState() {
    super.initState();
    // BackgroundService.stop();
    _loadAppRunState(); // Загружаем состояние при инициализации
  }

  void _startSendingRequests() {
    // Останавливаем предыдущий таймер, если он запущен
    _timer?.cancel(); // Используйте ?. чтобы избежать ошибки, если _timer уже null
    // Запускаем новый таймер
    _timer = Timer.periodic(Duration(seconds: _requestInterval), (timer) {
      _sendCurlRequest(); // Метод отправки запроса
    });
  }


  Future<void> _sendCurlRequest() async {
    try {
      final response = await http.get(Uri.parse(_urlString));
      if (response.statusCode == 200) {
        print("Запрос успешен: ${response.body}"); // Для отладки
      } else {
        print("Ошибка: ${response.statusCode}");
      }
    } catch (e) {
      print("Ошибка при отправке запроса: $e");
    }
  }

  Future<void> _loadAppRunState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _requestInterval = prefs.getInt('request_interval') ?? 10; // Загружаем интервал отправки
      _controller.text = _requestInterval.toString(); // Устанавливаем текст в TextField
      _appRun = prefs.getBool('appRun') ?? true; // По умолчанию true, если значение не найдено
      if (_appRun) {
        _startSendingRequests(); // Начинаем отправку запросов, если приложение запущено
      }
    });
  }

  Future<void> _saveSettings() async {
    String inputValue = _controller.text; // Получаем значение из TextField
    int? numberValue = int.tryParse(inputValue); // Пробуем преобразовать строку в число

    // Проверка на корректность ввода
    if (numberValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректное целое число')),
      );
      return; // Выход из метода, если значение не число
    }

    if (numberValue < _minValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите целое число не меньше 10')),
      );
      return; // Выход из метода, если значение меньше минимального
    }

    // Если все проверки пройдены, сохраняем значение
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('request_interval', numberValue); // Сохраняем значение в SharedPreferences
    setState(() {
      _requestInterval = numberValue; // Обновляем переменную _requestInterval
    });
    print('Значение сохранено: $numberValue'); // Для отладки

    if (_appRun) {
      _startSendingRequests(); // Перезапускаем таймер
    }
  }


  void _minimizeApp() {
    // Действие для закрытия или сворачивания приложения
    if (Platform.isAndroid) {
      // SystemNavigator.pop();
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Свернуть приложение не поддерживается на этой платформе')),
      );
    }

    if (_appRun) {
      print("RUN!!!!!");
      // BackgroundService.start();
    }
  }

  void _sendStop() async {
    setState(() {
      _appRun = false; // Установка состояния
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appRun', _appRun); // Сохраняем состояние в SharedPreferences

    // BackgroundService.stop();
    _timer?.cancel(); // Остановка таймера
    print('Отправка IP прекращена'); // Для отладки
  }

  void _sendStart() async {
    setState(() {
      _appRun = true; // Установка состояния
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appRun', _appRun); // Сохраняем состояние в SharedPreferences

    // BackgroundService.start();
    _startSendingRequests(); // (Не обязательно, если запускается через службу)
    print('Отправка IP возобновлена'); // Для отладки
  }

  @override
  void dispose() {
    _timer?.cancel(); // Удаляем таймер при уничтожении
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('App for email'), // Заголовок
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Отступы по бокам
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Начинаем размещение с верха
          children: <Widget>[
            const SizedBox(height: 20), // Отступ сверху
            const Text(
              'Приложение для отправки IP-адресов. Необходимо для работы с Email.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black), // Цвет текста по умолчанию
                children: <TextSpan>[
                  const TextSpan(text: 'Статус приложения: '),
                  TextSpan(
                    text: _appRun ? 'отправляет запросы' : 'не отправляет запросы',
                    style: TextStyle(
                      color: _appRun ? Colors.green : Colors.red, // Зеленый, если отправляет запросы, красный в противном случае
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Отступ между текстом и остальной частью
            const Text(
              'Настройки приложения', // Второй заголовок
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20), // Отступ между заголовками и остальной частью
            const Text(
              'Отправлять запрос раз в:',
            ),
            // Используем Row для размещения TextField и кнопки рядом
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 120, // Ширина текстового поля
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Целое число',
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Отступ между полем и кнопкой
                Row(
                  children: [
                    const Text('сек'), // Добавленный текст
                    const SizedBox(width: 10), // Отступ между текстом и кнопкой
                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _minimizeApp, // Свернуть приложение
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Цвет кнопки
              ),
              child: const Text('Свернуть приложение'),
            ),
            const SizedBox(height: 20), // Увеличиваем отступ между кнопками
            if (_appRun) ...[
              ElevatedButton(
                onPressed: _sendStop, // Прекратить отправку IP
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // Цвет кнопки
                ),
                child: const Text('Прекратить отправку IP'),
              ),
            ],
            if (!_appRun) ...[
              ElevatedButton(
                onPressed: _sendStart, // Возобновить отправку IP
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Цвет кнопки
                ),
                child: const Text('Возобновить отправку IP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
