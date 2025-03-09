// services/api_service_recompensas.dart
import 'package:dio/dio.dart';

class ApiServiceRecompensas {
  final Dio _dio = Dio();
  // Base URL de tu API (sin la parte específica de usuarios)
  final String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  /// Obtiene los puntos del usuario
  Future<int> getPuntosUsuario(String token, String userId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/usuarios/puntos/$userId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data['puntos'] ?? 0;
    } catch (e) {
      throw Exception('Error al obtener puntos: $e');
    }
  }

  /// Canjea la recompensa Premium enviando un body vacío
  Future<void> canjearRecompensaPremium(String token, String userId) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/usuarios/suscripcion/$userId',
        data: {}, // Enviar body vacío
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Error: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error al canjear recompensa: $e');
    }
  }
}
