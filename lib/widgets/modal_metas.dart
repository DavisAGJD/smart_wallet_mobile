import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:dio/dio.dart';
import '../services/api_service_metas.dart';

class MetasModal extends StatefulWidget {
  final VoidCallback onMetaCreated;

  const MetasModal({super.key, required this.onMetaCreated});

  @override
  _MetasModalState createState() => _MetasModalState();
}

class _MetasModalState extends State<MetasModal> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategoryId;
  TextEditingController nombreController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  TextEditingController montoController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  final ApiServiceGetCategoryMetas _categoryService =
      ApiServiceGetCategoryMetas();
  final ApiServiceMetas _metaService = ApiServiceMetas();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriasList = await _categoryService.getCategoriasMetas();
      setState(() {
        categories = categoriasList;
        if (categories.isNotEmpty) {
          selectedCategoryId = categories[0]['categoria_meta_id'].toString();
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar('Error al cargar categorías: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategoryId == null) return;

    setState(() => isSaving = true);

    try {
      final metaData = {
        'nombre_meta': nombreController.text,
        'monto_objetivo': double.parse(montoController.text),
        'fecha_limite': selectedDate.toIso8601String(),
        'descripcion': descripcionController.text,
        'categoria_meta_id': selectedCategoryId!,
      };

      await _metaService.crearMeta(metaData);

      widget.onMetaCreated();
      Navigator.of(context).pop();
      _showSuccessSnackbar('Meta creada exitosamente!');
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? 'Error desconocido';
      _showErrorSnackbar('Error: $errorMessage');
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    } finally {
      setState(() => isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  'Agregar Meta',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // Campo Nombre
                TextFormField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.title, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  validator: (value) => value!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 20),

                // Campo Descripción
                TextFormField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon:
                        Icon(Icons.description, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Selector de Fecha
                ListTile(
                  title: const Text("Fecha Límite"),
                  subtitle: Text("${selectedDate.toLocal()}".split(' ')[0]),
                  trailing: Icon(Icons.calendar_today, color: Colors.grey[600]),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Campo Monto
                TextFormField(
                  controller: montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto Objetivo',
                    prefixIcon:
                        Icon(Icons.monetization_on, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Requerido';
                    if (double.tryParse(value) == null)
                      return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Selector de Categoría
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField2<String>(
                        value: selectedCategoryId,
                        items: categories
                            .map((category) => DropdownMenuItem<String>(
                                  value:
                                      category['categoria_meta_id'].toString(),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(
                                            category['nombre_categoria']),
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 10),
                                      Text(category['nombre_categoria']),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() => selectedCategoryId = newValue);
                        },
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15)),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: MaterialStateProperty.all(6),
                            thumbVisibility: MaterialStateProperty.all(true),
                          ),
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
                        validator: (value) =>
                            value == null ? 'Seleccione una categoría' : null,
                      ),
                const SizedBox(height: 30),

                // Botón Guardar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: isSaving ? null : _submitForm,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar Meta',
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
