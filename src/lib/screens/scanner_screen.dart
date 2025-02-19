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
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Tienda: $_detectedStore"),
            Text(
                "Total: ${_detectedTotal?.toStringAsFixed(2) ?? 'No detectado'}"),
            const SizedBox(height: 20),
            if (_detectedTotal == null)
              const Text("¿Deseas reintentar el escaneo?",
                  style: TextStyle(color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Reintentar"),
          ),
          if (_detectedTotal != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Confirmar"),
            ),
        ],
      ),
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
