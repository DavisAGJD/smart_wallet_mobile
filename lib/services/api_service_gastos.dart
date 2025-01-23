import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceGastos {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> getGastosPaginados(
      String userId, int page, int limit) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/gastos/paginados',
        queryParameters: {
          'usuario_id': userId,
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener los gastos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los gastos: $e');
    }
  }
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
