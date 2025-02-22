import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/first_screen.dart'; // Onboarding
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  // Si hay token, va a '/main', si no, a '/first' (onboarding)
  runApp(MyApp(initialRoute: token != null ? '/main' : '/first'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({this.initialRoute = '/first'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finanzas Personales',
      initialRoute: initialRoute,
      routes: {
        '/first': (context) => FirstScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MainScreen(),
        // Puedes agregar más rutas si las necesitas
      },
    );
  }
}
