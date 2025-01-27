import 'package:flutter/material.dart';

class RecordatoriosModal extends StatelessWidget {
  final Function(String, DateTime) onSave;

  RecordatoriosModal({required this.onSave});

  @override
  Widget build(BuildContext context) {
    TextEditingController descriptionController = TextEditingController();
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
                    Colors.greenAccent.withOpacity(0.2), // Fondo naranja claro
                child: Icon(
                  Icons.notifications,
                  color: Colors.green, // Ícono naranja
                  size: 40,
                ),
              ),
              const SizedBox(height: 15),

              // Título
              Text(
                'Agregar Recordatorio',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Texto negro
                ),
              ),
              const SizedBox(height: 20),

              // Campo de Descripción
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Comprar sabritas', // Placeholder
                  prefixIcon: Icon(Icons.description,
                      color: Colors.grey[600]), // Ícono gris
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                maxLines: 3, // Permite múltiples líneas
              ),
              const SizedBox(height: 20),

              // Selector de Fecha
              ListTile(
                title: Text("Fecha de Recordatorio"),
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
                  String description = descriptionController.text;
                  onSave(description, selectedDate);
                  Navigator.of(context).pop();

                  // Mensaje de confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Recordatorio "$description" agregado'),
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
}
