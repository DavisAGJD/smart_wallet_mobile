import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ApiServiceLogin {
  final Dio _dio = Dio();

  Future<void> loginUsuario(String email, String password) async {
    try {
      final response = await _dio.post(
        'https://backend-smartwallet.onrender.com/api/usuarios/login',
        data: {
          'email': email,
          'password_usuario': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token == null) {
          throw Exception('El backend no devolvió el token');
        }

        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken['id'];

        if (userId == null) {
          throw Exception('El token no contiene el id del usuario');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId.toString()); // Guarda el userId
      } else {
        throw Exception('Error al iniciar sesión: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }
}
