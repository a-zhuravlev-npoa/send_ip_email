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
