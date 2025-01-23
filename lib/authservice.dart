import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}
