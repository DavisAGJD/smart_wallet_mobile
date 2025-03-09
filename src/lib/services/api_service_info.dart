import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Asegúrate de importar jwt_decoder

class ApiServiceInfo {
  final Dio _dio = Dio();
  final String baseUrl =
      'https://smartwallet-g4hadr0j.b4a.run/api/usuarios';

  // Método para obtener el token desde SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Método para obtener el userId desde SharedPreferences
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Método para obtener la información del usuario
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final token = await _getToken();
      final userId = await _getUserId();

      if (token == null || userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verifica si el token ha expirado
      if (JwtDecoder.isExpired(token)) {
        // Usa JwtDecoder.isExpired(token)
        throw Exception('El token ha expirado');
      }

      final response = await _dio.get(
        '$baseUrl/info-user/$userId', // Usa el userId en la URL
        options: Options(
          headers: {
            'Authorization': 'Bearer $token', // Incluye el token en los headers
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 403) {
        throw Exception(
            'Acceso denegado: No tienes permisos para acceder a este recurso');
      } else {
        throw Exception(
            'Error al obtener la información del usuario: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Acceso denegado: Verifica tus credenciales');
      } else {
        throw Exception('Error en la conexión: ${e.message}');
      }
    }
  }
}
