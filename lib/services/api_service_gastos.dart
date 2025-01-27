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

class CategoryService {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/categoriasGastos',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Extrae el ID y el nombre de cada categoría
        return data
            .map<Map<String, dynamic>>((category) => {
                  'categoria_gasto_id': category['categoria_gasto_id']
                      .toString(), // ID de la categoría
                  'nombre_categoria': category['nombre_categoria']
                      .toString(), // Nombre de la categoría
                })
            .toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}

class PostServiceGastos {
  final Dio _dio = Dio();
  final String token;

  PostServiceGastos({required this.token}) {
    _dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> addGasto(
      int categoryId, double amount, String description) async {
    try {
      final response = await _dio.post(
        'https://backend-smartwallet.onrender.com/api/gastos/create',
        data: {
          'categoria_gasto_id': categoryId, // Envía el ID de la categoría
          'monto': amount,
          'descripcion': description,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Gasto agregado exitosamente: ${response.data}');
      } else {
        throw Exception(
          'Error al agregar el gasto: Código ${response.statusCode}, Mensaje: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Error en la solicitud: ${e.message}');
    }
  }
}
