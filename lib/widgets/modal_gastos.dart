import 'package:flutter/material.dart';

class GastosModal extends StatelessWidget {
  final Function(String, double) onSave;

  GastosModal({required this.onSave});

  @override
  Widget build(BuildContext context) {
    String selectedCategory = 'Comida';
    TextEditingController amountController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context)
              .viewInsets
              .bottom, // Ajusta el espacio con el teclado
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
              // Icono superior
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

              // Título
              Text(
                'Agregar Gasto',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Categorías
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Comida', 'Automóvil', 'Hogar', 'Salud', 'Otros']
                    .map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 10),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedCategory = newValue;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
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
                onPressed: () {
                  double amount = double.tryParse(amountController.text) ?? 0.0;
                  onSave(selectedCategory, amount);
                  Navigator.of(context).pop();

                  // Mensaje de confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Gasto de \$${amount.toStringAsFixed(2)} en $selectedCategory agregado'),
                    ),
                  );
                },
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
      case 'Comida':
        return Icons.restaurant;
      case 'Automóvil':
        return Icons.directions_car;
      case 'Hogar':
        return Icons.home;
      case 'Salud':
        return Icons.favorite;
      default:
        return Icons.more_horiz;
    }
  }
}
