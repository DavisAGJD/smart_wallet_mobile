import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceSignup {
  final Dio _dio = Dio();

  Future<void> registrarUsuario({
    required String nombreUsuario,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'https://backend-smartwallet.onrender.com/api/usuarios/register', // Asegúrate de que esta URL sea correcta
        data: {
          'nombre_usuario': nombreUsuario,
          'email': email,
          'password_usuario': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 201) {
        // Si el registro es exitoso, puedes manejar la respuesta aquí
        final token = response.data['token']; // Si el backend devuelve un token
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token); // Guarda el token en SharedPreferences
        }

        print('Usuario registrado exitosamente');
      } else {
        throw Exception('Error al registrar el usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al registrar el usuario: $e');
    }
  }
}