import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service_scaner.dart'; // Asegúrate de que la ruta sea la correcta

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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

  /// Captura una imagen utilizando la cámara.
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

  /// Envía la imagen capturada al servidor y muestra un diálogo de confirmación.
  Future<void> _uploadCapturedImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiServiceScaner();
      final responseData =
          await apiService.uploadImage(File(_capturedImage!.path));

      // Se espera que el back responda con 'detalles_scan' y 'transactionId'
      final detalles = responseData["data"]["detalles_scan"];
      final transactionId = responseData["data"]["transactionId"];

      // Mostrar diálogo de confirmación con los datos reconocidos.
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirmar Gasto"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Tienda: ${detalles["tienda"] ?? 'N/A'}"),
                Text("Total: ${detalles["total_escaneado"] ?? 'N/A'}"),
                const SizedBox(height: 12),
                const Text("¿Confirmas el gasto?"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await _confirmExpense(transactionId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gasto cancelado.")),
        );
      }
    } catch (e) {
      debugPrint("Error enviando imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al enviar la imagen.")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Envía la confirmación del gasto al servidor.
  Future<void> _confirmExpense(String transactionId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiServiceScaner();
      final responseData = await apiService.confirmExpense(transactionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gasto confirmado exitosamente.")),
      );
      // Regresa a la pantalla anterior o realiza otra acción según convenga.
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error confirmando gasto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al confirmar el gasto.")),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Reinicia el estado del escáner para poder capturar una nueva imagen.
  void _resetScanner() {
    setState(() {
      _capturedImage = null;
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
                onPressed: _isProcessing ? null : _uploadCapturedImage,
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
