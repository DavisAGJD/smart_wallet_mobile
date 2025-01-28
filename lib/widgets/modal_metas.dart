import 'package:flutter/material.dart';

class MetasModal extends StatelessWidget {
  final Function(String, double, DateTime) onSave;

  MetasModal({required this.onSave});

  @override
  Widget build(BuildContext context) {
    String selectedCategory = 'Ahorro';
    TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono superior
              CircleAvatar(
                radius: 40,
                backgroundColor:
                    Colors.greenAccent.withOpacity(0.2), // Fondo verde claro
                child: Icon(
                  Icons.flag,
                  color: Colors.green, // Ícono verde
                  size: 40,
                ),
              ),
              const SizedBox(height: 15),

              // Título
              Text(
                'Agregar Meta',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Texto negro
                ),
              ),
              const SizedBox(height: 20),

              // Categorías
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Ahorro', 'Viaje', 'Educación', 'Otros']
                    .map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: Colors.grey[600], // Ícono gris
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
                  labelText: 'Monto Objetivo',
                  prefixIcon: Icon(Icons.monetization_on,
                      color: Colors.grey[600]), // Ícono gris
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Selector de Fecha
              ListTile(
                title: Text("Fecha Límite"),
                subtitle: Text(
                  "${selectedDate.toLocal()}".split(' ')[0],
                ),
                trailing: Icon(Icons.calendar_today,
                    color: Colors.grey[600]), // Ícono gris
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedDate) {
                    selectedDate = picked;
                  }
                },
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Botón verde
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                onPressed: () {
                  double amount = double.tryParse(amountController.text) ?? 0.0;
                  onSave(selectedCategory, amount, selectedDate);
                  Navigator.of(context).pop();

                  // Mensaje de confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Meta de \$${amount.toStringAsFixed(2)} en $selectedCategory agregada'),
                    ),
                  );
                },
                child: Text(
                  'Guardar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto blanco
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
      case 'Ahorro':
        return Icons.savings;
      case 'Viaje':
        return Icons.flight;
      case 'Educación':
        return Icons.school;
      default:
        return Icons.more_horiz;
    }
  }
}
