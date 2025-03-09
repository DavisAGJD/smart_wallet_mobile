import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceNotifications {
  final Dio _dio = Dio();
  final String baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api/notificaciones';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<dynamic>> getNotificationsByUser(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await _dio.get(
        '$baseUrl/user/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener notificaciones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  Future<void> updateNotification(String notificationId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await _dio.put(
        '$baseUrl/update/$notificationId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Error al actualizar notificación');
      }
    } catch (e) {
      throw Exception('Error al actualizar notificación: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }
      
      final response = await _dio.delete(
        '$baseUrl/delete/$notificationId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Error al eliminar notificación');
      }
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }
}
