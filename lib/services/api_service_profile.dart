import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiServiceProfile {
  final Dio _dio = Dio();

  Future<void> updateUser({
    required String usuarioId,
    String? name,
    String? username,
    String? email,
    String? password,
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

      if (updateData.isEmpty) {
        throw Exception('No hay campos para actualizar');
      }

      final response = await _dio.put(
        'https://backend-smartwallet.onrender.com/api/usuarios/update/$usuarioId',
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar el perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar el perfil: $e');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
