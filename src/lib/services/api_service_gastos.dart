import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceGastos {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> getGastosByUserId(String userId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/gastos/user/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Manejar el caso en el que la API devuelve un objeto { data: [...] }
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }

        // Manejar el caso en el que la API devuelve una lista directamente
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }

        throw Exception('Estructura de respuesta inesperada');
      } else {
        throw Exception('Error al obtener los gastos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los gastos: $e');
    }
  }

  Future<Map<String, dynamic>> getGastosPaginadosByUserId(
      String userId, int page, int limit) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Usuario no autenticado');

      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/gastos/user/$userId/paginados',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return response.data; // Debe incluir 'data' y 'pagination'
      } else {
        throw Exception(
            'Error al obtener los gastos paginados: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener los gastos paginados: $e');
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
                  'categoria_gasto_id':
                      category['categoria_gasto_id'].toString(),
                  'nombre_categoria': category['nombre_categoria'].toString(),
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
          'categoria_gasto_id': categoryId,
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

class DeleteServiceGastos {
  final Dio _dio = Dio();
  final String token;

  DeleteServiceGastos({required this.token}) {
    _dio.options.headers = {
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> deleteGasto(String gastoId) async {
    try {
      final response = await _dio.delete(
        'https://backend-smartwallet.onrender.com/api/gastos/delete/$gastoId',
      );
      if (response.statusCode == 200) {
        print('Gasto eliminado exitosamente: ${response.data}');
      } else {
        throw Exception(
          'Error al eliminar el gasto: Código ${response.statusCode}, Mensaje: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Error en la solicitud: ${e.message}');
    }
  }
}

class PutServiceGastos {
  final Dio _dio = Dio();
  final String token;

  PutServiceGastos({required this.token}) {
    _dio.options.headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> updateGasto(
      String gastoId, int categoryId, double amount, String description) async {
    try {
      final response = await _dio.put(
        'https://backend-smartwallet.onrender.com/api/gastos/update/$gastoId',
        data: {
          'categoria_gasto_id': categoryId,
          'monto': amount,
          'descripcion': description,
        },
      );
      if (response.statusCode == 200) {
        print('Gasto actualizado exitosamente: ${response.data}');
      } else {
        throw Exception(
          'Error al actualizar el gasto: Código ${response.statusCode}, Mensaje: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Error en la solicitud: ${e.message}');
    }
  }
}

class ApiServiceGastosGrafica {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> obtenerGastosPorUsuario(
      String usuarioId, String token) async {
    try {
      final response = await _dio.get(
        'https://backend-smartwallet.onrender.com/api/gastos/user/$usuarioId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (error) {
      print('Error al obtener los gastos del usuario: $error');
      throw error;
    }
  }
}
