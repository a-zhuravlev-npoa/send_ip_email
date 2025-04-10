import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

final String urlString = "http://mail.him-met.ru:83/set-ip/";

Future<void> sendCurlRequest(String nameStr) async {
  if (nameStr.isEmpty) return; // Не отправляем запрашиваемый, если имя пустое

  try {
    String responseStr = '$urlString?name=$nameStr';
    final response = await http.get(Uri.parse(responseStr));
    print("Отправляю запрос: $responseStr");
    print("Получаю ответ: ${response.statusCode}");

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
  final TextEditingController _controller = TextEditingController(text: '10');
  String? _name;
  final TextEditingController _nameController = TextEditingController();
  bool _sendRequest = false;
  late int _requestInterval;

  @override
  void initState() {
    super.initState();
    _loadAppRunState();
    _loadName();
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
      _nameController.text = _name ?? '';
    });
  }

  Future<void> _saveName() async {
    String userName = _nameController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
    setState(() {
      _name = userName;
    });
  }

  void _sendStart() {
    if (_name == null || _name!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы не задали имя')),
      );
      return;
    }

    setState(() {
      _sendRequest = true;
    });

    Timer.periodic(Duration(seconds: _requestInterval), (timer) {
      if (_sendRequest) {
        sendCurlRequest(_name!);
      } else {
        timer.cancel();
      }
    });
  }

  void _sendStop() {
    setState(() {
      _sendRequest = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App for Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            const Text(
              'Приложение для отправки IP-адресов.',
              style: TextStyle(fontSize: 14),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Ваше имя'),
              onChanged: (value) => _saveName(),
            ),
            const SizedBox(height: 10),
            const Text('Интервал отправки запросов (в секундах):'),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Сохранение настроек
                int? newInterval = int.tryParse(_controller.text);
                if (newInterval != null && newInterval >= 10) {
                  setState(() {
                    _requestInterval = newInterval;
                  });
                }
              },
              child: const Text('Сохранить настройки'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendRequest ? _sendStop : _sendStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _sendRequest ? Colors.orange : Colors.green,
              ),
              child: Text(_sendRequest ? 'Прекратить отправку IP' : 'Включить отправку IP'),
            ),
          ],
        ),
      ),
    );
  }
}
