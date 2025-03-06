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
  }

  @override
  void dispose() {
    _scanController.dispose();
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Confirmar Gasto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 10),
                  // Fila para mostrar el nombre de la tienda con botón de edición
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Tienda:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: isEditing
                            ? TextField(
                                controller: storeController,
                                decoration: const InputDecoration(
                                  hintText: "Ingrese tienda",
                                ),
                              )
                            : Text(
                                storeController.text.isEmpty
                                    ? 'Desconocida'
                                    : storeController.text,
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.check : Icons.edit,
                          color: Colors.green,
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
                  // Fila para mostrar el total
                  Row(
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _detectedTotal != null
                            ? _detectedTotal!.toStringAsFixed(2)
                            : 'No detectado',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_detectedTotal == null)
                    const Text(
                      "¿Deseas reintentar el escaneo?",
                      style: TextStyle(color: Colors.orange),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Reintentar',
                            style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      if (_detectedTotal != null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                              style: TextStyle(fontSize: 16)),
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
      appBar: AppBar(
        title: const Text('Escáner Inteligente'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_useFlash ? Icons.flash_on : Icons.flash_off),
            onPressed: () => setState(() => _useFlash = !_useFlash),
          )
        ],
      ),
      body: _buildMainContent(),
      floatingActionButton: _capturedImage != null
          ? FloatingActionButton(
              onPressed: _resetScanner,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildMainContent() {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _buildCameraPreview(),
        if (_isScanning) _buildScanOverlay(),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildCameraPreview() {
    return _capturedImage == null
        ? CameraPreview(_cameraController!)
        : InteractiveViewer(
            maxScale: 4.0, child: Image.file(File(_capturedImage!.path)));
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) => CustomPaint(
        painter: _ScanOverlayPainter(
          animationValue: _scanController.value,
          flashActive: _useFlash,
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text("Analizando recibo...",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double animationValue;
  final bool flashActive;

  _ScanOverlayPainter({required this.animationValue, this.flashActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final scanLineY = size.height * animationValue;
    const guideHeight = 200.0;
    final guideWidth = size.width * 0.8;

    // Área de escaneo
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: guideWidth,
      height: guideHeight,
    );

    // Sombreado exterior
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(scanRect),
      ),
      backgroundPaint,
    );

    // Borde del área
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(scanRect, borderPaint);

    // Línea de escaneo animada
    final linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(scanRect.left, scanLineY),
        Offset(scanRect.right, scanLineY),
        [Colors.transparent, _lineColor, Colors.transparent],
        [0.1, 0.5, 0.9],
      )
      ..strokeWidth = 4.0;

    final clippedLineY = scanLineY.clamp(scanRect.top, scanRect.bottom);
    canvas.drawLine(
      Offset(scanRect.left, clippedLineY),
      Offset(scanRect.right, clippedLineY),
      linePaint,
    );

    // Efecto de flash
    if (flashActive) {
      final flashPaint = Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..blendMode = BlendMode.plus;
      canvas.drawRect(scanRect.inflate(20), flashPaint);
    }
  }

  Color get _lineColor => flashActive
      ? Colors.amber.withOpacity(0.8)
      : Colors.redAccent.withOpacity(0.8);

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) => true;
}
