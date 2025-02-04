import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:smart_wallet/services/api_service_metas.dart';

class MetasAddAmountModal extends StatefulWidget {
  const MetasAddAmountModal({super.key});

  @override
  _MetasAddAmountModalState createState() => _MetasAddAmountModalState();
}

class _MetasAddAmountModalState extends State<MetasAddAmountModal> {
  final _formKey = GlobalKey<FormState>();
  String? selectedMetaId;
  final ApiServiceGetMetas _getMetas = ApiServiceGetMetas();
  List<Meta> metas = [];
  bool isLoading = true;
  TextEditingController montoController = TextEditingController();
  bool isSaving = false; // Nuevo estado para controlar el guardado

  @override
  void initState() {
    super.initState();
    _fetchMetas();
  }

  Future<void> _fetchMetas() async {
    try {
      final metasList = await _getMetas.getMetasWithCategories();
      setState(() {
        metas = metasList;
        if (metas.isNotEmpty) {
          selectedMetaId = metas.first.metaId.toString();
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Error al cargar metas: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  Future<void> _updateMetaAmount() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedMetaId == null) {
      _showErrorSnackbar('Selecciona una meta');
      return;
    }

    setState(() => isSaving = true);

    try {
      final metaId = int.parse(selectedMetaId!);
      final monto = double.parse(montoController.text);

      await ApiServiceUpdateAmount().updateAmount(metaId, monto);

      _showSuccessSnackbar('Monto actualizado correctamente');
      Navigator.of(context).pop();
    } on FormatException {
      _showErrorSnackbar('Formato de monto inválido');
    } catch (e) {
      _showErrorSnackbar('Error al actualizar: $e');
    } finally {
      setState(() => isSaving = false);
    }
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
                  child: const Icon(Icons.flag, color: Colors.green, size: 40),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Agregar Monto',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField2<String>(
                        value: selectedMetaId,
                        items: metas
                            .map((meta) => DropdownMenuItem<String>(
                                  value: meta.metaId.toString(),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(meta.categoriaNombre),
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 10),
                                      Text(meta.nombreMeta),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() => selectedMetaId = newValue);
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                        ),
                      ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto a agregar',
                    prefixIcon:
                        Icon(Icons.monetization_on, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Requerido';
                    final amount = double.tryParse(value);
                    if (amount == null) return 'Número inválido';
                    if (amount <= 0) return 'El monto debe ser positivo';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: isSaving ? null : _updateMetaAmount,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ahorro':
        return Icons.savings;
      case 'viaje':
        return Icons.flight;
      case 'emprendimiento':
        return Icons.business;
      case 'proyecto':
        return Icons.assignment;
      case 'caridad':
        return Icons.volunteer_activism;
      case 'logro':
        return Icons.emoji_events;
      case 'medio ambiente':
        return Icons.eco;
      case 'seguridad':
        return Icons.security;
      case 'estrella':
        return Icons.star;
      default:
        return Icons.more_horiz;
    }
  }
}
