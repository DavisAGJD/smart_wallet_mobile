// services/api_service_reportes.dart
import 'package:dio/dio.dart';

class ApiServiceReportes {
  final Dio _dio = Dio();
  final String _baseUrl =
      'https://smartwallet-g4hadr0j.b4a.run/api/reportes';

  /// Crea un nuevo reporte.
  /// [token]: Token de autenticación.
  /// [reportData]: Datos del reporte a crear.
  Future<dynamic> crearReporte(
      String token, Map<String, dynamic> reportData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/create',
        data: reportData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print("Error al crear reporte: $e");
      throw Exception("Error al crear reporte: $e");
    }
  }

  /// Obtiene los reportes del usuario.
  /// [token]: Token de autenticación.
  /// [usuarioId]: ID del usuario cuyos reportes se desean obtener.
  Future<dynamic> obtenerReportesPorUsuario(
      String token, String usuarioId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/user/$usuarioId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print("Error al obtener reportes del usuario: $e");
      throw Exception("Error al obtener reportes del usuario: $e");
    }
  }
}
