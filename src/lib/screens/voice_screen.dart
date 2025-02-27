import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/TFLiteService.dart';
import '../services/api_service_gastos.dart'; // Para PostServiceGastos y getToken

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({Key? key}) : super(key: key);

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  final TFLiteService _tfliteService = TFLiteService();
  Map<String, dynamic> _lastResult = {};

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _tfliteService.loadModel();
    } catch (e) {
      _showErrorDialog('Error inicializando modelo: $e');
    }
  }

  void _startListening() async {
    try {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _transcription = result.recognizedWords;
          }),
        );
      } else {
        _showErrorDialog('Reconocimiento de voz no disponible');
      }
    } catch (e) {
      _showErrorDialog('Error al iniciar grabación: $e');
    }
  }

  void _stopListening() async {
    try {
      await _speech.stop();
      setState(() => _isListening = false);

      if (_transcription.isNotEmpty) {
        final result = _tfliteService.predict(_transcription);
        setState(() => _lastResult = result);
        final confirm = await _showResultDialog(result);
        if (confirm == true) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showErrorDialog('Error procesando audio: $e');
    }
  }

  // Mapea la etiqueta predicha a un ID de categoría (ejemplo usando índice + 1).
  int _mapCategoryLabelToId(String label) {
    int index = _tfliteService.categories.indexOf(label);
    return (index >= 0) ? index + 1 : 0;
  }

  // Registra el gasto usando PostServiceGastos.
  Future<void> _confirmExpense(Map<String, dynamic> result) async {
    try {
      int categoryId = _mapCategoryLabelToId(result['category']['label']);
      double amount = double.tryParse(result['amount']) ?? 0.0;
      String description = result['description'];

      String? token = await getToken();
      if (token == null) {
        _showErrorDialog('Token no disponible');
        return;
      }
      PostServiceGastos postService = PostServiceGastos(token: token);
      await postService.addGasto(categoryId, amount, description);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Gasto de \$${amount.toStringAsFixed(2)} registrado exitosamente')),
      );
    } catch (e) {
      _showErrorDialog('Error registrando el gasto: $e');
    }
  }

  // Muestra el diálogo de confirmación con opciones.
  Future<bool?> _showResultDialog(Map<String, dynamic> result) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        // Responsividad: ajusta tamaños según MediaQuery.
        final media = MediaQuery.of(context);
        return AlertDialog(
          title: const Text('Resultado del análisis'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: media.size.width * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categoría: ${result['category']['label']}',
                      style: TextStyle(fontSize: media.size.width * 0.045)),
                  const SizedBox(height: 8),
                  Text('Confianza: ${result['category']['confidence']}',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: media.size.width * 0.04)),
                  const SizedBox(height: 8),
                  Text('Monto: \$${result['amount']}',
                      style: TextStyle(
                          fontSize: media.size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 8),
                  Text('Descripción: ${result['description']}',
                      style: TextStyle(fontSize: media.size.width * 0.045)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Deshacer'),
            ),
            TextButton(
              onPressed: () async {
                await _confirmExpense(result);
                Navigator.pop(context, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro por Voz'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(media.size.width * 0.05),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: media.size.width * 0.3,
                color: _isListening ? Colors.green : Colors.grey,
              ),
              SizedBox(height: media.size.height * 0.03),
              Text(
                _isListening ? 'Escuchando...' : 'Presiona para grabar',
                style: TextStyle(fontSize: media.size.width * 0.06),
              ),
              SizedBox(height: media.size.height * 0.03),
              Container(
                padding: EdgeInsets.all(media.size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _transcription.isEmpty
                      ? 'Di algo como: "Gasté 50 pesos en el supermercado"'
                      : _transcription,
                  style: TextStyle(fontSize: media.size.width * 0.045),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: media.size.height * 0.03),
              ElevatedButton.icon(
                icon: Icon(_isListening ? Icons.stop : Icons.mic_none,
                    size: media.size.width * 0.06),
                label: Text(_isListening ? 'Detener' : 'Iniciar',
                    style: TextStyle(fontSize: media.size.width * 0.05)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: media.size.width * 0.08,
                      vertical: media.size.height * 0.02),
                ),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
