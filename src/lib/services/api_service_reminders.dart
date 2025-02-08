import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceRecordatorios {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://backend-smartwallet.onrender.com/api';

  Future<void> crearRecordatorio(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioId = await _getUserId();

      if (token == null || usuarioId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _dio.post(
        '$_baseUrl/recordatorios/create',
        data: {
          ...data,
          'usuario_id': usuarioId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status == 201,
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al crear el recordatorio');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? e.message);
    }
  }

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}

class ApiServicesGetRecordatorios {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://backend-smartwallet.onrender.com/api';

  Future<List<Recordatorio>> getRecordatorio() async {
    try {
      final userId = await _getUserId();
      final token = await _getToken();

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final int userIdInt = int.parse(userId);

      final response = await _dio.get(
        '$_baseUrl/recordatorios/user/$userIdInt',
        options: Options(
          headers: {'Authorization': 'Bearer $token'}, // Agregar header
          validateStatus: (status) => status == 200 || status == 500,
        ),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((item) => Recordatorio.fromJson(item))
            .toList();
      } else if (response.data?['error'] != null) {
        throw Exception(response.data!['error']);
      } else {
        throw Exception('Error desconocido al obtener recordatorios');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.message);
    } on FormatException {
      throw Exception('Formato de ID de usuario inválido');
    }
  }

  static Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}

class Recordatorio {
  final int recordatorioId;
  final String descripcion;
  final DateTime fecha;

  Recordatorio({
    required this.recordatorioId,
    required this.descripcion,
    required this.fecha,
  });

  factory Recordatorio.fromJson(Map<String, dynamic> json) {
    return Recordatorio(
      recordatorioId: json['recordatorio_id'] as int,
      descripcion: json['descripcion'] as String,
      fecha: DateTime.parse(json['fecha_recordatorio'] as String),
    );
  }
}
