import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:async';


const startPeriodicTask = "ru.ssh.send_ip_email.startPeriodicTask";
final String urlString = "https://mail.him-met.ru/set-ip/";

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

@pragma('vm:entry-point')
void callbackDispatcher() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  static const String incrementCountCommand = 'incrementCount';

  int _count = 0;

  void _incrementCount() {
    _count++;

    // Update notification content.
    FlutterForegroundTask.updateService(
      notificationTitle: 'Доступ к почте',
      notificationText: 'Отправлено запросов: $_count',
    );

    sendCurlRequest();
    // Send data to main isolate.
    FlutterForegroundTask.sendDataToMain(_count);
  }

  // Called when the task is started.
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
    _incrementCount();
  }

  // Called based on the eventAction set in ForegroundTaskOptions.
  @override
  void onRepeatEvent(DateTime timestamp) {
    _incrementCount();
  }

  // Called when the task is destroyed.
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('onDestroy');
  }

  // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
    if (data == incrementCountCommand) {
      _incrementCount();
    }
  }

  // Called when the notification button is pressed.
  @override
  void onNotificationButtonPressed(String id) async {
    print('onNotificationButtonPressed: $id');
    if (id == 'btn_close') {
      // Останавливаем сервис
      await FlutterForegroundTask.stopService();

      // Отправляем данные в основное приложение
      FlutterForegroundTask.sendDataToMain({'action': 'stopService'});
    }
  }


  // Called when the notification itself is pressed.
  @override
  void onNotificationPressed() {
    print('onNotificationPressed');
  }

  // Called when the notification itself is dismissed.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  // runApp(const MyApp());
  runApp(const ExampleApp());
}


// Главный виджет приложения
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const MyHomePage(), // Изменили на MyHomePage
        '/second': (context) => const SecondPage(),
      },
      initialRoute: '/',
    );
  }
}

// Вторая страница
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('pop this page'),
        ),
      ),
    );
  }
}

// Главная страница с состоянием
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

  final ValueNotifier<Object?> _taskDataListenable = ValueNotifier(null);

  Future<void> _requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
    await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        // When you call this function, will be gone to the settings page.
        // So you need to explain to the user why set it.
        await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  void _initService() {

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
        'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
        showBadge: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_requestInterval * 1000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  // Добавим слушатель на изменение текста
  @override
  void initState() {
    super.initState();
    _loadAppRunState();
    _loadName(); // Загружаем имя при инициализации

    _nameController.addListener(_saveName); // Добавляем слушатель
  }


  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        notificationIcon: const NotificationIcon(
          metaDataName: 'ru.ssh.send_ip_email.service.ICON',
          //metaDataName: '@drawable/ic_notification', // Ссылка на маленькую иконку
          backgroundColor: Colors.blue,     // Задайте цвет фона
        ),
        notificationButtons: [
          const NotificationButton(id: 'btn_close', text: 'закрыть'),
        ],
        notificationInitialRoute: '/',
        callback: callbackDispatcher,
      );
    }
  }

  Future<ServiceRequestResult> _stopService() {
    return FlutterForegroundTask.stopService();
  }


  void _onReceiveTaskData(Object? data) {
    print('onReceiveTaskData: $data');

    if (data is Map<String, dynamic> && data['action'] == 'stopService') {
      setState(() {
        _sendRequest = false; // Останавливаем отправку запросов
      });

      // Сохраняем состояние
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('sendRequest', false);
      });
    }
  }



  void _startSendingRequests() async {
    // Запускаем первый раз по кнопке - потом по расписанию
    // sendCurlRequest();

    _startService();
  }

  void _loadAppRunState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _requestInterval = prefs.getInt('request_interval') ?? 10;
      _controller.text = _requestInterval.toString();
      _sendRequest = prefs.getBool('sendRequest') ?? false;
      if (_sendRequest) {
        _startSendingRequests();
      }
    });

    // Слушатель данных от фонового процесса
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request permissions and initialize the service.
      _requestPermissions();
      _initService();
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
    print('Значение сохранено: $numberValue');

    if (_sendRequest) {
      _startSendingRequests();
    }

    _initService();

    return 1;
  }

  void _minimizeApp() {
    if (Platform.isAndroid) {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Свернуть приложение не поддерживается на этой платформе')),
      );
    }
  }

  void _sendStop() async {
    setState(() {
      _sendRequest = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);

    _stopService();
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

    // Неверны интервал
    int result = await _saveSettings();
    if (result == 0) {
      return;
    }

    setState(() {
      _sendRequest = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sendRequest', _sendRequest);
    _startSendingRequests();
    print('Отправка IP включена');
  }

  @override
  void dispose() {
    _nameController.removeListener(_saveName); // Удаляем слушатель
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _taskDataListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('App for email'),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
              const SizedBox(height: 10),
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

              const SizedBox(height: 40),


              // Имя не задано и запросы не отправляются
              if(_nameIsEmpty && !_sendRequest) ...[
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
              ],

              // Имя задано и запросы не отправляются
              if (!_nameIsEmpty && !_sendRequest) ...[
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
              ],

              // Имя задано и запросы отправляются
              if (!_nameIsEmpty && _sendRequest) ...[
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

              Divider(
                color: Colors.blue.withOpacity(0.4), // Цвет линии
                thickness: 1.3, // Толщина линии
                height: 5.0, // Высота вокруг линии
              ),
              Divider(
                color: Colors.blue.withOpacity(0.4), // Цвет линии
                thickness: 1.3, // Толщина линии
                height: 5.0, // Высота вокруг линии
              ),


              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _minimizeApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('Свернуть приложение'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
