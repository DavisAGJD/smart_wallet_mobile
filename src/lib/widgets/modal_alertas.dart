import 'package:flutter/material.dart';
import '../services/api_service_reminders.dart';

class RecordatoriosModal extends StatefulWidget {
  const RecordatoriosModal({super.key});

  @override
  _RecordatoriosModalState createState() => _RecordatoriosModalState();
}

class _RecordatoriosModalState extends State<RecordatoriosModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  DateTime _fechaSeleccionada = DateTime.now();
  final ApiServiceRecordatorios _apiService = ApiServiceRecordatorios();
  bool _isSaving = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _apiService.crearRecordatorio({
        'descripcion': _descripcionController.text,
        'fecha_recordatorio': _fechaSeleccionada.toIso8601String(),
      });

      _showSuccessSnackbar('Recordatorio creado exitosamente');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.greenAccent.withOpacity(0.2),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Agregar Recordatorio',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Comprar sabritas',
                    prefixIcon:
                        Icon(Icons.description, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La descripción es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Fecha de Recordatorio"),
                  subtitle: Text(
                    "${_fechaSeleccionada.toLocal()}".split(' ')[0],
                  ),
                  trailing: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _fechaSeleccionada,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _fechaSeleccionada) {
                      setState(() => _fechaSeleccionada = picked);
                    }
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
