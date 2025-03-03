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
        // Analiza múltiples gastos en el input de voz
        final results = _tfliteService.predictMultipleExpenses(_transcription);
        if (results.isNotEmpty) {
          bool? confirm = await _showExpensesListDialog(results);
          if (confirm == true) {
            await _insertExpenses(results);
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      _showErrorDialog('Error procesando audio: $e');
    }
  }

  /// Mapea la etiqueta predicha a un ID de categoría (ejemplo usando índice + 1).
  int _mapCategoryLabelToId(String label) {
    int index = _tfliteService.categories.indexOf(label);
    return (index >= 0) ? index + 1 : 0;
  }

  /// Registra un gasto usando PostServiceGastos.
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
    } catch (e) {
      _showErrorDialog('Error registrando el gasto: $e');
    }
  }

  /// Muestra un modal con la lista de gastos detectados para que el usuario los revise.
  /// Muestra un modal con la lista de gastos detectados para que el usuario los revise.
  Future<bool?> _showExpensesListDialog(List<Map<String, dynamic>> expenses) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final media = MediaQuery.of(context);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
                  'Gastos detectados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.grey),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Colors.grey),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        leading:
                            const Icon(Icons.receipt_long, color: Colors.green),
                        title: Text(
                          expense['category']['label'],
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          "Monto: \$${expense['amount']}\nDescripción: ${expense['description']}",
                        ),
                        trailing: Text(
                          expense['category']['confidence'],
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Confirmar',
                          style: TextStyle(fontSize: 16)),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// Inserta los gastos uno a uno sin mostrar una barra de progreso.
  Future<void> _insertExpenses(List<Map<String, dynamic>> expenses) async {
    for (var expense in expenses) {
      await _confirmExpense(expense);
      // Permite ceder el control a la UI si es necesario.
      await Future.delayed(const Duration(milliseconds: 100));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("Todos los gastos fueron insertados (${expenses.length})"),
      ),
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
                icon: Icon(
                  _isListening ? Icons.stop : Icons.mic_none,
                  size: media.size.width * 0.06,
                ),
                label: Text(
                  _isListening ? 'Detener' : 'Iniciar',
                  style: TextStyle(fontSize: media.size.width * 0.05),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: media.size.width * 0.08,
                    vertical: media.size.height * 0.02,
                  ),
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
