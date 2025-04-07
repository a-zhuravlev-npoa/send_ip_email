import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(const MyApp());
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
  bool _sendRequest = false; // Отправка запросов включена / выключена
  final String _urlString = "http://mail.him-met.ru:83/set-ip/";
  Timer? _timer;

  final TextEditingController _nameController = TextEditingController(); // Контроллер для имени (????????)
  String? _name; // Имя пользователя
  bool _nameIsEmpty = true; // При первом запуске приложения - имя всегда пустое

  // Добавим слушатель на изменение текста
  @override
  void initState() {
    super.initState();
    _loadAppRunState();
    _loadName(); // Загружаем имя при инициализации

    _nameController.addListener(_saveName); // Добавляем слушатель
  }

  void _startSendingRequests() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _requestInterval), (timer) {
      _sendCurlRequest();
    });
  }

  Future<void> _sendCurlRequest() async {
    try {
      String param = 'myParam';
      final response = await http.get(Uri.parse('$_urlString?name=$_name'));

      print(response);

      if (response.statusCode == 200) {
        print("Запрос успешен: ${response.body}");
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
      _requestInterval = prefs.getInt('request_interval') ?? 10;
      _controller.text = _requestInterval.toString();
      _sendRequest = prefs.getBool('sendRequest') ?? false;
      if (_sendRequest) {
        _startSendingRequests();
      }
    });
  }

  Future<void> _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name'); // Загружаем имя
      _nameIsEmpty = _name!.isEmpty;
      _nameController.text = _name ?? ''; // Устанавливаем текст в TextField
    });
  }

  // Метод для сохранения имени в SharedPreferences
  Future<void> _saveName() async {
    String userName = _nameController.text; // Получаем значение из TextField
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName); // Сохраняем имя в SharedPreferences
    setState(() {
      _name = userName; // Обновляем состояние имени
      // print(_name);
    });
  }

  Future<void> _saveSettings() async {
    String inputValue = _controller.text;
    int? numberValue = int.tryParse(inputValue);

    if (numberValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите корректное целое число')),
      );
      return;
    }

    if (numberValue < _minValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите целое число не меньше 10')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('request_interval', numberValue);
    setState(() {
      _requestInterval = numberValue;
    });
    print('Значение сохранено: $numberValue');

    if (_sendRequest) {
      _startSendingRequests();
    }
  }

  void _minimizeApp() {
    if (Platform.isAndroid) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Свернуть приложение не поддерживается на этой платформе')),
      );
    }

    if (_sendRequest) {
      print("RUN!!!!!");
    }
  }

  void _sendStop() async {
    setState(() {
      _sendRequest = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);
    _timer?.cancel();
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
      _sendRequest = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);
    _startSendingRequests();
    print('Отправка IP включена');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.removeListener(_saveName); // Удаляем слушатель
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('App for email'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              'Приложение для отправки IP-адресов. Необходимо для работы с Email.',
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
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                children: <TextSpan>[
                  const TextSpan(text: 'Отправлять запросы от имени: '),
                  TextSpan(
                    text: (_name != null && _name!.isNotEmpty) ? _name : 'имя не задано',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Настройки приложения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ваше имя:',
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ваше имя',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) {
                if (text.isNotEmpty) {
                  // Изменяем первую букву на заглавную
                  final capitalized = text[0].toUpperCase() + text.substring(1);
                  _nameController.value = _nameController.value.copyWith(
                    text: capitalized,
                    selection: TextSelection.collapsed(offset: capitalized.length),
                  );
                }
              },
            ),

            // Имя не задано
            if (_name == null || _name!.isEmpty) ...[
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  text: 'Имя не должно быть пустым! Введите имя и нажмите кнопку "Включить отправку IP."',
                  style: TextStyle(color: Colors.red), // Здесь устанавливаем цвет текста
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Text(
              'Отправлять запрос раз в:',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 120,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Целое число',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    const Text('сек'),
                    const SizedBox(width: 10),
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
              onPressed: _minimizeApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Свернуть приложение'),
            ),
            const SizedBox(height: 20),



            // Имя не задано и запросы не отправляются
            if(_nameIsEmpty && !_sendRequest) ...[
              ElevatedButton(
                onPressed: _sendStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Включить отправку IP'),
              ),
            ],

            // Имя задано и запросы не отправляются
            if (!_nameIsEmpty && !_sendRequest) ...[
              ElevatedButton(
                onPressed: _sendStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Включить отправку IP'),
              ),
            ],

            // Имя задано и запросы отправляются
            if (!_nameIsEmpty && _sendRequest) ...[
              ElevatedButton(
                onPressed: _sendStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Прекратить отправку IP'),
              ),
            ],

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
