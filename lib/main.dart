import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

final String urlString = "http://mail.him-met.ru:83/set-ip/";

Future<void> sendCurlRequest() async {
  final prefs = await SharedPreferences.getInstance();
  String nameStr = prefs.getString('user_name') ?? '';

  try {
    String responseStr = '$urlString?name=$nameStr';
    final response = await http.get(Uri.parse(responseStr));
    print("Отправляю запрос: $responseStr");
    print("Получаю ответ: $response");

    if (response.statusCode == 200) {
      print("Запрос успешен: ${response.body}");
    } else {
      print("Ошибка: ${response.statusCode}");
    }
  } catch (e) {
    print("Ошибка при отправке запроса: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email Sender App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController(text: '10'); // Значение по умолчанию 10
  final int _minValue = 10; // Минимальное значение
  int _requestInterval = 10; // Значение интервала по умолчанию
  bool _sendRequest = false; // Отправка запросов включена / выключена

  String? _name; // Имя пользователя
  final TextEditingController _nameController = TextEditingController(); // Контроллер для имени (????????)
  bool _nameIsEmpty = true; // При первом запуске приложения - имя всегда пустое

  @override
  void initState() {
    super.initState();
    _loadAppRunState();
    _loadName(); // Загружаем имя при инициализации

    _nameController.addListener(_saveName); // Добавляем слушатель
  }

  Future<void> _loadAppRunState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _requestInterval = prefs.getInt('request_interval') ?? 10;
      _controller.text = _requestInterval.toString();
      _sendRequest = prefs.getBool('sendRequest') ?? false;
    });
  }

  Future<void> _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name');
      _nameIsEmpty = _name == null || _name!.isEmpty; // Убедиться, что мы проверяем на null
      _nameController.text = _name ?? ''; // Установите текст контроллера
    });
  }

  Future<void> _saveName() async {
    String userName = _nameController.text; // Получаем значение из TextField
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName); // Сохраняем имя в SharedPreferences
    setState(() {
      _name = userName; // Обновляем состояние имени
      // print(_name);
    });
  }

  Future<int> _saveSettings() async {
    String inputValue = _controller.text;
    int? numberValue = int.tryParse(inputValue);

    if (numberValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректное целое число')),
      );
      return 0;
    }

    if (numberValue < _minValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите целое число не меньше 10')),
      );
      return 0;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('request_interval', numberValue);
    setState(() {
      _requestInterval = numberValue;
    });

    Timer.periodic(Duration(seconds: _requestInterval), (timer) {
      if (_sendRequest) {
        sendCurlRequest();
      } else {
        timer.cancel();
      }
    });

    return 1;
  }

  Future<void> _sendStop() async {
    setState(() {
      _sendRequest = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);

    print('Отправка IP прекращена');
  }

  void _sendStart() async {
    if (_name == null || _name!.isEmpty) {
      _nameIsEmpty = true;
      _sendRequest = false;
      print('Имя не задано, отправка IP невозможна');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не задали имя')),
      );
      return;
    }

    setState(() {
      _nameIsEmpty = false;
    });

    int result = await _saveSettings();
    if (result == 0) {
      return;
    }

    setState(() {
      _sendRequest = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);
    print('Отправка IP включена');
  }

  @override
  void dispose() {
    _nameController.removeListener(_saveName); // Удаляем слушатель
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('App for Email'),
      ),
      body: Center(
        child: Container(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'Приложение для отправки IP-адресов.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                      children: <TextSpan>[
                        const TextSpan(text: 'Статус приложения: '),
                        TextSpan(
                          text: _sendRequest ? 'отправляет запросы' : 'не отправляет запросы',
                          style: TextStyle(
                            color: _sendRequest ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Ваше имя:'),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ваше имя',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Интервал отправки запросов (в секундах):'),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Целое число',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Кнопки для управления отправкой IP
                  if (_name == null || _name!.isEmpty) ...[
                    ElevatedButton(
                      onPressed: _sendStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      ),
                      child: const Text('Включить отправку IP',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else if (!_sendRequest) ...[
                    ElevatedButton(
                      onPressed: _sendStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      ),
                      child: const Text('Включить отправку IP',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _sendStop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                      ),
                      child: const Text('Прекратить отправку IP',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
