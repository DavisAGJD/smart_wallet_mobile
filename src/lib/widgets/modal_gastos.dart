import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../services/api_service_gastos.dart';

class GastosModal extends StatefulWidget {
  final Function(String, double, String) onSave;
  final String token;

  GastosModal({required this.onSave, required this.token});

  @override
  _GastosModalState createState() => _GastosModalState();
}

class _GastosModalState extends State<GastosModal> {
  String? selectedCategory;
  TextEditingController amountController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  late PostServiceGastos _postServiceGastos;

  @override
  void initState() {
    super.initState();
    _postServiceGastos = PostServiceGastos(
      token: widget.token,
    );
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoryService = CategoryService();
      final fetchedCategories = await categoryService.fetchCategories();

      setState(() {
        // Eliminar duplicados
        categories = fetchedCategories.toSet().toList();

        // Asegurarse de que selectedCategory tenga un valor válido
        if (categories.isNotEmpty) {
          selectedCategory = categories[0]['categoria_gasto_id'].toString();
        } else {
          selectedCategory = null;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las categorías: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.greenAccent.withOpacity(0.2),
                child: Icon(
                  Icons.attach_money,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Agregar Gasto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // DropdownButton2 con scroll
              isLoading
                  ? CircularProgressIndicator()
                  : DropdownButton2<String>(
                      value: selectedCategory,
                      items:
                          categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['categoria_gasto_id'].toString(),
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category['nombre_categoria']),
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 10),
                              Text(category['nombre_categoria']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        scrollbarTheme: ScrollbarThemeData(
                          radius: const Radius.circular(40),
                          thickness: MaterialStateProperty.all(6),
                          thumbVisibility: MaterialStateProperty.all(true),
                        ),
                      ),
                      menuItemStyleData: const MenuItemStyleData(
                        height: 40,
                      ),
                      buttonStyleData: ButtonStyleData(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                      ),
                    ),
              const SizedBox(height: 20),

              // Campo de Descripción
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),

              // Campo de Monto
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                onPressed: () async {
                  if (selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por favor, selecciona una categoría'),
                      ),
                    );
                    return;
                  }

                  double amount = double.tryParse(amountController.text) ?? 0.0;
                  String description = descriptionController.text;

                  try {
                    int categoryId =
                        int.parse(selectedCategory!); // Convierte a int
                    await _postServiceGastos.addGasto(
                        categoryId, amount, description);
                    widget.onSave(selectedCategory!, amount, description);
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Gasto de \$${amount.toStringAsFixed(2)} agregado'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al agregar el gasto: $e'),
                      ),
                    );
                  }
                },
                child: Text(
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
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Alimentacion':
        return Icons.restaurant;
      case 'Transporte':
        return Icons.directions_bus;
      case 'Entretenimiento':
        return Icons.movie;
      case 'Educacion':
        return Icons.school;
      case 'Salud':
        return Icons.favorite;
      case 'Hogar':
        return Icons.home;
      case 'Ropa':
        return Icons.checkroom;
      case 'Tecnologia':
        return Icons.computer;
      case 'Viajes':
        return Icons.flight;
      case 'Otros':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}
