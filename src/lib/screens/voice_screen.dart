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
      // Inicializamos con callbacks para estado y errores
      bool available = await _speech.initialize(
        onStatus: (status) {
          // Si el servicio se detiene y aún se desea grabar, reiniciamos después de un breve retraso
          if (status == "notListening" && _isListening) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening) {
                _startListening();
              }
            });
          }
        },
        onError: (errorNotification) {
          _showErrorDialog(
              'Error de reconocimiento: ${errorNotification.errorMsg}');
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) => setState(() {
            _transcription = result.recognizedWords;
          }),
          // Removemos listenFor y pauseFor para dejar la grabación activa
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
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

  int _mapCategoryLabelToId(String label) {
    int index = _tfliteService.categories.indexOf(label);
    return (index >= 0) ? index + 1 : 0;
  }

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
            constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gastos detectados',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 1, color: Colors.grey),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          leading: Icon(Icons.receipt_long,
                              color: Colors.green.shade700),
                          title: Text(
                            expense['category']['label'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "Monto: \$${expense['amount']}\nDescripción: ${expense['description']}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              expense['category']['confidence'],
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
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
                            borderRadius: BorderRadius.circular(10)),
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

  Future<void> _insertExpenses(List<Map<String, dynamic>> expenses) async {
    for (var expense in expenses) {
      await _confirmExpense(expense);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Registro por Voz',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(media.size.width * 0.05),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.mic,
                    size: media.size.width * 0.3,
                    color: _isListening ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isListening ? 'Grabando...' : 'Presiona para grabar',
                  style: TextStyle(
                    fontSize: media.size.width * 0.06,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: EdgeInsets.all(media.size.width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _transcription.isEmpty
                        ? 'Di algo como: "Gasté 50 pesos en el supermercado"'
                        : _transcription,
                    style: TextStyle(
                      fontSize: media.size.width * 0.045,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.symmetric(
                      horizontal: media.size.width * 0.08,
                      vertical: media.size.height * 0.02,
                    ),
                    elevation: 5,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
