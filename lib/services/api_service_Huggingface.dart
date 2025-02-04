import 'package:dio/dio.dart';

Future<String> getHuggingFaceResponse(String userInput) async {
  final String apiKey = '';
  final String endpoint = '';

  Dio dio = Dio();

  final Map<String, dynamic> body = {
    "inputs": userInput,
  };

  try {
    Response response = await dio.post(
      endpoint,
      data: body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data[0]['generated_text'];
    } else {
      throw Exception("Error: ${response.statusCode}");
    }
  } on DioException catch (e) {
    throw Exception("Error en la solicitud: ${e.message}");
  }
}

void processTextWithHuggingFace(String text) async {
  try {
    String aiResponse = await getHuggingFaceResponse(text);
    print("Respuesta de la IA: $aiResponse");
    // Aquí puedes procesar la respuesta y guardar el gasto en tu base de datos
  } catch (e) {
    print("Error al procesar la solicitud: $e");
  }
}