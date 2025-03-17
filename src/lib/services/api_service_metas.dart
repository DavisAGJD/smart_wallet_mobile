import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceGetCategoryMetas {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  Future<List<Map<String, dynamic>>> getCategoriasMetas() async {
    try {
      final response = await _dio.get('$_baseUrl/categoriasMetas');
      return (response.data as List).map<Map<String, dynamic>>((category) {
        return {
          'categoria_meta_id': category['categoria_meta_id']?.toString() ?? '0',
          'nombre_categoria':
              category['nombre_categoria']?.toString() ?? 'Sin categoría',
        };
      }).toList();
    } on DioException catch (e) {
      throw Exception('Error obteniendo categorías: ${e.message}');
    }
  }

  Future<Map<int, String>> getCategoriasMap() async {
    // Cambiar a Map<int, String>
    try {
      final response = await _dio.get('$_baseUrl/categoriasMetas');
      final Map<int, String> categorias = {};
      for (var category in response.data) {
        final id = category['categoria_meta_id'] as int; // Obtener como int
        final nombre = category['nombre_categoria'] as String;
        categorias[id] = nombre;
      }
      return categorias;
    } on DioException catch (e) {
      throw Exception('Error obteniendo categorías: ${e.message}');
    }
  }
}

class ApiServiceMetas {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  Future<void> crearMeta(Map<String, dynamic> metaData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No hay token disponible');

      final response = await _dio.post(
        '$_baseUrl/metas/create',
        data: metaData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al crear la meta');
      }
    } on DioException catch (e) {
      throw Exception('Error: ${e.response?.data?['error'] ?? e.message}');
    }
  }

  Future<void> deleteMeta(int metaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('No hay token disponible');

      final response = await _dio.delete(
        '$_baseUrl/metas/delete/$metaId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar la meta');
      }
    } on DioException catch (e) {
      throw Exception(
          'Error al eliminar la meta: ${e.response?.data?['error'] ?? e.message}');
    }
  }
}

class ApiServiceUpdateAmount {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  Future<void> updateAmount(int metaId, double montoAdicional) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) throw Exception('No hay token disponible');

      final response = await _dio.put(
        '$_baseUrl/metas/updateMonto/$metaId',
        data: {'montoAdicional': montoAdicional},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar el monto: ${response.data['error']}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['error'] ?? e.message;
      throw Exception('Error de conexión: $errorMessage');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}

class ApiServiceGetMetas {
  final Dio _dio = Dio();
  final ApiServiceGetCategoryMetas _categoryService =
      ApiServiceGetCategoryMetas();
  static const String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  Future<List<Meta>> getMetasWithCategories() async {
    try {
      final categoriasMap = await _categoryService.getCategoriasMap();
      final userId = await _getUserId();

      final response =
          await _dio.get('$_baseUrl/metas/user/${int.parse(userId!)}');

      return (response.data as List).map((e) {
        final metaJson = e as Map<String, dynamic>;
        return Meta.fromJson({
          'meta_id': metaJson['meta_id'],
          'nombre_meta': metaJson['nombre_meta'],
          'monto_objetivo': metaJson['monto_objetivo'],
          'fecha_limite': metaJson['fecha_limite'],
          'monto_actual': metaJson['monto_actual'],
          'descripcion': metaJson['descripcion'],
          'categoria_meta_id':
              metaJson['categoria_meta_id'], // No convertir a String
        }, categoriasMap);
      }).toList();
    } on DioException catch (e) {
      throw Exception('Error: ${e.response?.data['error'] ?? e.message}');
    }
  }

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}

class Meta {
  final int metaId;
  final String nombreMeta;
  final double montoObjetivo;
  final DateTime fechaLimite;
  final double montoActual;
  final String descripcion;
  final String categoriaNombre;
  final int categoriaMetaId;

  Meta({
    required this.metaId,
    required this.nombreMeta,
    required this.montoObjetivo,
    required this.fechaLimite,
    required this.montoActual,
    required this.descripcion,
    required this.categoriaNombre,
    required this.categoriaMetaId,
  });

  factory Meta.fromJson(
      Map<String, dynamic> json, Map<int, String> categoriasMap) {
    return Meta(
      metaId: json['meta_id'] as int,
      nombreMeta: json['nombre_meta'] as String,
      montoObjetivo: double.parse(json['monto_objetivo'].toString()),
      fechaLimite: DateTime.parse(json['fecha_limite'].toString()),
      montoActual: double.parse(json['monto_actual'].toString()),
      descripcion: json['descripcion'] as String,
      categoriaNombre:
          categoriasMap[json['categoria_meta_id'] as int] ?? 'Sin categoría',
      categoriaMetaId: json['categoria_meta_id'] as int,
    );
  }
}
