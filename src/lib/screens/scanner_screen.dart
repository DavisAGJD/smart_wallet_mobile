import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// Paquetes para preprocesamiento de imagen
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Función auxiliar para aplicar umbralización a una imagen en escala de grises.
/// Recorre cada píxel y, según el valor, lo asigna a blanco o negro.
img.Image applyThreshold(img.Image src, int threshold) {
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      int pixel = src.getPixel(x, y);
      int r = img.getRed(pixel); // En imagenes en escala de grises, R=G=B
      if (r > threshold) {
        src.setPixel(x, y, 0xFFFFFFFF); // Blanco
      } else {
        src.setPixel(x, y, 0xFF000000); // Negro
      }
    }
  }
  return src;
}

/// Obtiene el token desde SharedPreferences.
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  XFile? _capturedImage;
  late TextRecognizer _textRecognizer;

  double? _detectedAmount;
  int? _detectedCategory;
  String? _detectedText;

  @override
  void initState() {
    super.initState();
    // Inicializamos el TextRecognizer de ML Kit para textos latinos.
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  /// Inicializa la cámara solicitando permisos y configurando el controlador.
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint("Permiso de cámara no concedido");
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No hay cámaras disponibles");
        return;
      }
      final camera = cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Error al inicializar la cámara: $e");
    }
  }

  /// Toma una foto utilizando la cámara.
  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint("Error al capturar la imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al capturar la imagen")),
      );
    }
  }

  /// Preprocesa la imagen: convierte a escala de grises y aplica umbralización.
  /// Esto ayuda a resaltar el texto para mejorar el OCR.
  Future<File> _preProcessImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return originalFile;

      // Convertir a escala de grises.
      final grayscaleImage = img.grayscale(decodedImage);

      // Aplicar umbralización (binarización). Ajusta el valor de threshold según tus pruebas.
      final thresholdedImage = applyThreshold(grayscaleImage, 140);

      // Guardar la imagen procesada en un archivo temporal.
      final tempDir = await getTemporaryDirectory();
      final processedFile = File(
          '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await processedFile.writeAsBytes(img.encodeJpg(thresholdedImage));
      return processedFile;
    } catch (e) {
      debugPrint("Error en el preprocesamiento de imagen: $e");
      return originalFile;
    }
  }

  /// Procesa la imagen capturada: preprocesa, extrae el texto, detecta el monto y la categoría,
  /// y muestra un diálogo de confirmación para registrar el gasto.
  Future<void> _processCapturedImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      // Preprocesar la imagen para mejorar el OCR.
      final originalFile = File(_capturedImage!.path);
      final processedFile = await _preProcessImage(originalFile);

      final inputImage = InputImage.fromFilePath(processedFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      _detectedText = recognizedText.text;
      debugPrint("Texto detectado: $_detectedText");

      if (_detectedText != null && _isValidTicket(_detectedText!)) {
        final amount = _extractAmount(_detectedText!);
        if (amount != null) {
          final category = _detectCategory(_detectedText!);
          _detectedAmount = amount;
          _detectedCategory = category;
          await _showConfirmationDialog(amount, category);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("No se pudo extraer el monto del ticket.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Ticket no válido o sin texto detectable.")),
        );
      }
    } catch (e) {
      debugPrint("Error al procesar la imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al procesar la imagen.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Valida si el ticket es reconocido a partir de palabras clave o patrones de moneda.
  bool _isValidTicket(String text) {
    final validKeywords = [
      'oxxo',
      'chedraui',
      'soriana',
      'bodega aurrera',
      'walmart',
      "sam's",
      'va y ven',
      'costco',
      'mcdonald',
      'burger king',
      'kfc',
      'taco bell',
      'domino',
      'pizza hut',
      'kekén',
      'bepensa',
      'dondé',
      'tere cazola',
      'la anita',
      'sal sol',
      'cinepolis',
      'cinemex',
      'ticket',
      'recibo',
      'factura',
      'boleta'
    ];
    final lowerText = text.toLowerCase();
    final hasKeyword = validKeywords.any((kw) => lowerText.contains(kw));
    final currencyRegex = RegExp(r'\$?\s*\d+(?:[,.]\d{1,2})');
    final hasCurrency = currencyRegex.hasMatch(text);
    return hasKeyword || hasCurrency;
  }

  /// Extrae el monto total del ticket utilizando palabras clave y expresiones regulares.
  /// Primero busca en líneas que contengan las palabras clave y, si no se encuentra, usa un fallback.
  double? _extractAmount(String text) {
    final lines = text.split('\n');
    final keywords = ["total", "importe", "monto", "pago"];
    final amountRegex = RegExp(r'\$?\s*(\d+(?:[,.]\d{1,2})?)');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      if (keywords.any((kw) => lowerLine.contains(kw))) {
        // Intenta extraer en la misma línea.
        final match = amountRegex.firstMatch(line);
        if (match != null && match.groupCount >= 1) {
          final numStr = match.group(1)!.replaceAll(',', '.');
          final value = double.tryParse(numStr);
          if (value != null) return value;
        }
        // Revisa hasta 3 líneas siguientes.
        for (int j = i + 1; j < min(i + 4, lines.length); j++) {
          final nextLine = lines[j].trim();
          final nextMatch = amountRegex.firstMatch(nextLine);
          if (nextMatch != null && nextMatch.groupCount >= 1) {
            final numStr = nextMatch.group(1)!.replaceAll(',', '.');
            final value = double.tryParse(numStr);
            if (value != null) return value;
          }
        }
      }
    }

    // Fallback: extrae todos los números y asume que el mayor es el total.
    final amounts = <double>[];
    for (final line in lines) {
      for (final match in amountRegex.allMatches(line)) {
        final numStr = match.group(1)!.replaceAll(',', '.');
        final value = double.tryParse(numStr);
        if (value != null) {
          amounts.add(value);
        }
      }
    }
    if (amounts.isNotEmpty) {
      return amounts.reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  /// Detecta la categoría del ticket basándose en palabras clave.
  /// Si no se detecta ninguna coincidencia fuerte, se asigna a "Otros" (ID 10).
  int _detectCategory(String text) {
    final lowerText = text.toLowerCase();
    final Map<int, List<String>> categoryKeywords = {
      1: [
        'oxxo',
        'chedraui',
        'soriana',
        'bodega aurrera',
        'walmart',
        "sam's",
        'costco',
        'mcdonald',
        'burger king',
        'kfc',
        'taco bell',
        'domino',
        'pizza hut',
        'supermercado',
        'restaurante',
        'comida'
      ],
      2: [
        'va y ven',
        'uber',
        'didi',
        'cabify',
        'taxi',
        'transporte',
        'metro',
        'autobús',
        'bus'
      ],
      3: [
        'cinepolis',
        'cinemex',
        'teatro',
        'concierto',
        'espectáculo',
        'película',
        'peliculas'
      ],
      4: ['universidad', 'colegio', 'escuela', 'instituto', 'educacion'],
      5: ['hospital', 'clínica', 'salud', 'farmacia', 'medicina'],
      6: ['hogar', 'casa', 'muebles', 'decoración', 'furniture'],
      7: ['ropa', 'moda', 'tienda de ropa', 'vestimenta', 'calzado'],
      8: [
        'tecnología',
        'electronics',
        'apple',
        'samsung',
        'gadgets',
        'computadora'
      ],
      9: [
        'aeromexico',
        'volaris',
        'interjet',
        'avianca',
        'hotel',
        'resort',
        'turismo',
        'viaje'
      ],
      11: ['kekén', 'bepensa', 'dondé', 'tere cazola', 'la anita', 'sal sol'],
    };

    int bestCategory = 10; // Por defecto: "Otros"
    int bestCount = 0;

    categoryKeywords.forEach((categoryId, keywords) {
      int count = keywords.fold(0, (prev, keyword) {
        return lowerText.contains(keyword.toLowerCase()) ? prev + 1 : prev;
      });
      if (count > bestCount) {
        bestCount = count;
        bestCategory = categoryId;
      }
    });

    return bestCategory;
  }

  /// Muestra un diálogo de confirmación con la información del gasto detectado.
  /// Si se confirma, se llama al método para registrar el gasto en la API.
  Future<void> _showConfirmationDialog(double amount, int category) async {
    final categoryName = _getCategoryName(category);
    Icon categoryIcon;
    switch (category) {
      case 1:
        categoryIcon =
            const Icon(Icons.restaurant, size: 48, color: Colors.orange);
        break;
      case 2:
        categoryIcon =
            const Icon(Icons.directions_car, size: 48, color: Colors.blue);
        break;
      case 3:
        categoryIcon = const Icon(Icons.movie, size: 48, color: Colors.purple);
        break;
      case 4:
        categoryIcon = const Icon(Icons.school, size: 48, color: Colors.green);
        break;
      case 5:
        categoryIcon =
            const Icon(Icons.local_hospital, size: 48, color: Colors.red);
        break;
      case 6:
        categoryIcon = const Icon(Icons.home, size: 48, color: Colors.brown);
        break;
      case 7:
        categoryIcon =
            const Icon(Icons.shopping_bag, size: 48, color: Colors.pink);
        break;
      case 8:
        categoryIcon =
            const Icon(Icons.devices, size: 48, color: Colors.indigo);
        break;
      case 9:
        categoryIcon = const Icon(Icons.flight, size: 48, color: Colors.teal);
        break;
      case 11:
        categoryIcon =
            const Icon(Icons.local_offer, size: 48, color: Colors.deepOrange);
        break;
      default:
        categoryIcon =
            const Icon(Icons.receipt_long, size: 48, color: Colors.grey);
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              categoryIcon,
              const SizedBox(width: 8),
              Expanded(child: Text('Confirmar Gasto ($categoryName)')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Monto: \$${amount.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              const Text('¿Deseas registrar este gasto?',
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _registerExpense(amount, category);
    } else {
      _resetScanner();
    }
  }

  /// Retorna el nombre de la categoría según su ID.
  String _getCategoryName(int categoryId) {
    final names = {
      1: 'Alimentación',
      2: 'Transporte',
      3: 'Entretenimiento',
      4: 'Educación',
      5: 'Salud',
      6: 'Hogar',
      7: 'Ropa',
      8: 'Tecnología',
      9: 'Viajes',
      10: 'Otros',
      11: 'Ticket'
    };
    return names[categoryId] ?? 'Desconocido';
  }

  /// Realiza la llamada a la API para registrar el gasto.
  Future<void> _registerExpense(double amount, int category) async {
    final token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no autenticado")),
      );
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://backend-smartwallet.onrender.com/api/gastos/create',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'categoria_gasto_id': category,
          'monto': amount,
          'descripcion': 'Ticket escaneado automáticamente',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gasto registrado exitosamente.")),
        );
        // Regresamos al HomeScreen indicando que se registró el gasto.
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al registrar el gasto.")),
        );
        _resetScanner();
      }
    } catch (e) {
      debugPrint("Error registrando gasto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar el gasto.")),
      );
      _resetScanner();
    }
  }

  /// Reinicia el estado del escáner para permitir capturar un nuevo ticket.
  void _resetScanner() {
    setState(() {
      _capturedImage = null;
      _detectedAmount = null;
      _detectedCategory = null;
      _detectedText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escáner de Tickets'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isCameraInitialized
          ? (_capturedImage == null
              ? _buildCameraPreview()
              : _buildCapturedImagePreview())
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: _capturedImage == null
          ? FloatingActionButton(
              onPressed: _resetScanner,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  /// Vista previa de la cámara con botón para capturar la imagen.
  Widget _buildCameraPreview() {
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera),
              label: const Text('Tomar foto'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Vista previa de la imagen capturada con opciones para reintentar o procesar.
  Widget _buildCapturedImagePreview() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.file(
            File(_capturedImage!.path),
            fit: BoxFit.cover,
          ),
        ),
        if (_isProcessing) const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processCapturedImage,
                icon: const Icon(Icons.check),
                label: const Text('Procesar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
