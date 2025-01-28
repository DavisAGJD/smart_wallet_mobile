import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/first_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(
    initialRoute: token != null ? '/' : '/',
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({this.initialRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finanzas Personales',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => FirstScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
