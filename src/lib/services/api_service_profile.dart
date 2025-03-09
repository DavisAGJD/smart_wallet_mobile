import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiServiceProfile {
  final Dio _dio = Dio();

  Future<void> updateUser({
    required String usuarioId,
    String? name,
    String? username,
    String? email,
    String? password,
    String? income,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final updateData = <String, dynamic>{};
      if (name != null && name.isNotEmpty) {
        updateData['nombre_usuario'] = name;
      }
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }
      if (password != null && password.isNotEmpty) {
        updateData['password_usuario'] = password;
      }
      if (income != null && income.isNotEmpty) {
        updateData['ingresos'] = income;
      }

      if (updateData.isEmpty) {
        throw Exception('No hay campos para actualizar');
      }

      final response = await _dio.put(
        'https://smartwallet-g4hadr0j.b4a.run/api/usuarios/update/$usuarioId',
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar el perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }

  Future<void> updateUserImage({
    required String usuarioId,
    required File image,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(image.path, filename: fileName),
      });

      final response = await _dio.put(
        'https://smartwallet-g4hadr0j.b4a.run/api/usuarios/update-image/$usuarioId',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar la imagen: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar la imagen: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile({required String userId}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _dio.get(
        'https://smartwallet-g4hadr0j.b4a.run/api/usuarios/info-user/$userId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener datos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }
}

class FinancesApiService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> getGastosYSalario() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Usuario no autenticado');
    }

    final response = await _dio.get(
      'https://smartwallet-g4hadr0j.b4a.run/api/usuarios/gastoYSalario',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Error al obtener datos: ${response.statusCode}');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
