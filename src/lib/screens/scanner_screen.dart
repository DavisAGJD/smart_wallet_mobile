import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/api_service_scaner.dart';

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
  bool _useFlash = false;

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

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error inicializando cámara: $e");
    }
  }

  void _toggleUseFlash() {
    setState(() {
      _useFlash = !_useFlash;
    });
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      if (_useFlash) {
        await _cameraController!.setFlashMode(FlashMode.torch);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final image = await _cameraController!.takePicture();

      if (_useFlash) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

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

  // Función nueva: Compresión de imagen
  Future<File?> _compressImage(File imageFile) async {
    final compressedPath = "${imageFile.path}_compressed.jpg";

    try {
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        compressedPath,
        quality: 70,
      );

      if (compressedImage == null) {
        debugPrint("Error al comprimir la imagen");
        return null;
      }

      debugPrint("Imagen comprimida: ${compressedImage.path}");
      return File(compressedImage.path);
    } catch (e) {
      debugPrint("Error en compresión: $e");
      return null;
    }
  }

  Future<void> _uploadCapturedImage() async {
    if (_capturedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiServiceScaner();
      final originalImage = File(_capturedImage!.path);

      // Compresión añadida
      final compressedImage = await _compressImage(originalImage);
      if (compressedImage == null) {
        throw Exception("Error en compresión de imagen");
      }

      final responseData = await apiService.uploadImage(compressedImage);
      final detalles = responseData["data"]["detalles_scan"];
      final transactionId = responseData["data"]["transactionId"];

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

  Future<void> _confirmExpense(String transactionId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiServiceScaner();
      await apiService.confirmExpense(transactionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gasto confirmado exitosamente.")),
      );
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

  Widget _buildCameraPreview() {
    return Stack(
      children: [
        CameraPreview(_cameraController!),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: Icon(
              _useFlash ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
              size: 32,
            ),
            onPressed: _toggleUseFlash,
          ),
        ),
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
