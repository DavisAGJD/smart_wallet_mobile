import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/text_analysis.dart';
import '../services/api_service_scaner.dart';

class AdvancedScannerScreen extends StatefulWidget {
  const AdvancedScannerScreen({Key? key}) : super(key: key);

  @override
  _AdvancedScannerScreenState createState() => _AdvancedScannerScreenState();
}

class _AdvancedScannerScreenState extends State<AdvancedScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _useFlash = false;
  bool _isProcessing = false;
  bool _isScanning = true;
  XFile? _capturedImage;

  late AnimationController _scanController;
  late AnimationController _pulseController;
  Timer? _scanTimer;

  // Resultados de OCR
  String _detectedStore = '';
  double? _detectedTotal;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _scanTimer?.cancel();
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startAutoScan();
      }
    } catch (e) {
      debugPrint("Error inicializando cámara: $e");
    }
  }

  void _startAutoScan() {
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isProcessing && _isScanning) {
        _captureAndAnalyzeFrame();
      }
    });
  }

  Future<void> _captureAndAnalyzeFrame() async {
    try {
      final image = await _cameraController!.takePicture();
      final file = File(image.path);
      final text = await TextAnalysis.performOCR(file);

      if (TextAnalysis.isLikelyReceipt(text)) {
        _scanTimer?.cancel();
        setState(() {
          _capturedImage = image;
          _isScanning = false;
        });
        _processCapturedImage();
      }
    } catch (e) {
      debugPrint("Error en escaneo automático: $e");
    }
  }

  Future<void> _processCapturedImage() async {
    setState(() => _isProcessing = true);
    try {
      final file = File(_capturedImage!.path);
      final text = await TextAnalysis.performOCR(file);
      final analysis = await TextAnalysis.analyzeText(text);

      setState(() {
        _detectedStore = analysis['store'] ?? 'Desconocida';
        _detectedTotal = analysis['total'];
      });
      await _showConfirmationDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error procesando: $e")),
      );
      _resetScanner();
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _showConfirmationDialog() async {
    final TextEditingController storeController =
        TextEditingController(text: _detectedStore);
    bool isEditing = false;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final media = MediaQuery.of(context);
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 16,
            backgroundColor: Colors.grey[900],
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirmar Gasto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: Colors.white54),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Tienda:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: isEditing
                            ? TextField(
                                controller: storeController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: "Ingrese tienda",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white54),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                              )
                            : Text(
                                storeController.text.isEmpty
                                    ? 'Desconocida'
                                    : storeController.text,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            isEditing = !isEditing;
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _detectedTotal != null
                            ? _detectedTotal!.toStringAsFixed(2)
                            : 'No detectado',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_detectedTotal == null)
                    const Text(
                      "¿Deseas reintentar el escaneo?",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Reintentar',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      if (_detectedTotal != null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF228B22),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          onPressed: () {
                            setState(() {
                              _detectedStore = storeController.text;
                            });
                            Navigator.pop(context, true);
                          },
                          child: const Text('Confirmar',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    confirm == true ? _sendExpenseToBackend() : _resetScanner();
  }

  Future<void> _sendExpenseToBackend() async {
    try {
      await GastoService().postGasto(
        total: _detectedTotal!,
        tienda: _detectedStore,
      );
      Navigator.pop(context, true);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
      _resetScanner();
    }
  }

  void _resetScanner() {
    setState(() {
      _capturedImage = null;
      _detectedStore = '';
      _detectedTotal = null;
      _isScanning = true;
    });
    _startAutoScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Se puede dejar el AppBar sin el botón de flash para evitar duplicidad
      appBar: AppBar(
        title: const Text('Escáner Inteligente'),
        backgroundColor: const Color(0xFF228B22),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildCameraPreview(),
          if (_isScanning) _buildScanOverlay(),
          if (_isProcessing) _buildProcessingOverlay(),
          // Botón superpuesto para el control de linterna (flash)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _useFlash ? Icons.flash_on : Icons.flash_off,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () async {
                setState(() {
                  _useFlash = !_useFlash;
                });
                if (_cameraController != null) {
                  await _cameraController!.setFlashMode(
                    _useFlash ? FlashMode.torch : FlashMode.off,
                  );
                }
              },
            ),
          ),
          // Texto de instrucciones en la parte inferior
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Alinea tu ticket dentro del marco",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: _capturedImage != null
          ? FloatingActionButton(
              onPressed: _resetScanner,
              backgroundColor: const Color(0xFF228B22),
              child: const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildCameraPreview() {
    return _capturedImage == null
        ? CameraPreview(_cameraController!)
        : InteractiveViewer(
            maxScale: 4.0,
            child: Image.file(File(_capturedImage!.path)),
          );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanController, _pulseController]),
      builder: (context, _) => CustomPaint(
        painter: _ScanOverlayPainter(
          animationValue: _scanController.value,
          pulseValue: _pulseController.value,
          flashActive: _useFlash,
        ),
        child: Container(),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Analizando ticket...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double animationValue;
  final double? pulseValue;
  final bool flashActive;

  _ScanOverlayPainter({
    required this.animationValue,
    this.pulseValue,
    this.flashActive = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Área de escaneo: rectángulo redondeado centrado
    final guideHeight = 250.0;
    final guideWidth = size.width * 0.85;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: guideWidth,
      height: guideHeight,
    );
    final rrect = RRect.fromRectAndRadius(scanRect, const Radius.circular(20));

    // Fondo degradado en el exterior
    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.black.withOpacity(0.7),
          Colors.black.withOpacity(0.9),
        ],
      );
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(rrect),
      ),
      backgroundPaint,
    );

    // Borde animado con gradiente y efecto pulsante
    final gradient = ui.Gradient.linear(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.right, scanRect.bottom),
      [
        const Color(0xFF22c55e),
        const Color(0xFF16a34a),
      ],
    );
    final borderPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = (pulseValue ?? 1.0) * 4.0;
    canvas.drawRRect(rrect, borderPaint);

    // Línea de escaneo animada con efecto de destello
    final scanLineY = scanRect.top + (scanRect.height * animationValue);
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(scanRect.left, scanLineY),
        Offset(scanRect.right, scanLineY),
        [
          Colors.transparent,
          const Color(0xFF22c55e).withOpacity(0.8),
          Colors.transparent,
        ],
        const [0.3, 0.5, 0.7],
      )
      ..strokeWidth = 4.0;
    final clippedLineY = scanLineY.clamp(scanRect.top, scanRect.bottom);
    canvas.drawLine(
      Offset(scanRect.left, clippedLineY),
      Offset(scanRect.right, clippedLineY),
      linePaint,
    );

    // Efecto de flash sutil si está activo
    if (flashActive) {
      final flashPaint = Paint()
        ..color = const Color(0xFF22c55e).withOpacity(0.15)
        ..blendMode = BlendMode.plus;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            scanRect.inflate(30), const Radius.circular(20)),
        flashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) => true;
}
