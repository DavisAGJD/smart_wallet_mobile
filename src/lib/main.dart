import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/first_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';

// GlobalKey para navegación global
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Callback para acciones en notificaciones
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  final payload = receivedAction.payload;
  if (payload != null && payload['screen'] == 'notifications') {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Awesome Notifications
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Notificaciones',
        channelDescription: 'Canal para notificaciones básicas',
        defaultColor: const Color(0xFF228B22),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
    ],
  );

  // Registrar el listener para acciones
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  // Solicitar permisos (especialmente para iOS)
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  // Lógica para definir la ruta inicial
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(
    initialRoute: token != null ? '/main' : '/first',
    navigatorKey: navigatorKey,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    Key? key,
    this.initialRoute = '/first',
    required this.navigatorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Finanzas Personales',
      initialRoute: initialRoute,
      routes: {
        '/first': (context) => FirstScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
        '/notifications': (context) => NotificationsScreen(userId: '1234'),
      },
    );
  }
}
