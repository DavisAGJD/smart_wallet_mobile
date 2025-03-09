import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

/// Obtiene el token desde SharedPreferences.
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

class ApiServiceScaner {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  /// Envía la imagen capturada al endpoint         `/scan`.
  /// Retorna la respuesta del servidor en formato Map.
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    FormData formData = FormData.fromMap({
      "image": await MultipartFile.fromFile(
        imageFile.path,
        filename: "ticket.jpg",
        contentType: MediaType("image", "jpeg"),
      ),
    });

    final response = await _dio.post(
      '$_baseUrl/scaner/scan',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Error al enviar la imagen');
    }
  }

  /// Envía la confirmación del gasto al endpoint `/confirm`.
  /// Retorna la respuesta del servidor en formato Map.
  Future<Map<String, dynamic>> confirmExpense(String transactionId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final response = await _dio.post(
      '$_baseUrl/scaner/confirm',
      data: {
        "transactionId": transactionId,
        "confirm": true,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Error al confirmar el gasto');
    }
  }
}

class GastoService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://smartwallet-g4hadr0j.b4a.run/api';

  Future<void> postGasto({
    required double total,
    required String tienda,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final usuarioId = await _getUserId();

      if (token == null || usuarioId == null) {
        throw Exception('Usuario no autenticado');
      }

      final data = {
        'total': total,
        'tienda': tienda,
        'usuario_id': usuarioId,
      };

      final response = await _dio.post(
        '$_baseUrl/gastos/gastoScan',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // Solo se considera exitosa la respuesta con status 201
          validateStatus: (status) => status == 201,
        ),
      );

      if (response.statusCode != 201) {
        throw Exception('Error al registrar el gasto');
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
