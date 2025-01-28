import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceArticles {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> getArticles() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/articles',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Asumimos que la respuesta es una lista de mapas que incluye imágenes
        if (response.data is List) {
          return (response.data as List)
              .map((article) => article as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception('Estructura de datos inesperada: ${response.data}');
        }
      } else {
        throw Exception('Error al obtener las noticias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener las noticias: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
