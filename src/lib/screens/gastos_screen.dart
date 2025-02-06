import 'package:flutter/material.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  // Lista de gastos
  List<int> gastos = List.generate(20, (index) => (index + 1) * 10);

  // Controlador del scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Escuchar el scroll
    _scrollController.addListener(_cargarMasGastos);
  }

  @override
  void dispose() {
    // Limpiar el controlador
    _scrollController.removeListener(_cargarMasGastos);
    _scrollController.dispose();
    super.dispose();
  }

  // Simular la carga de más datos
  void _cargarMasGastos() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        // Añade 10 elementos más a la lista
        int ultimoValor = gastos.last;
        gastos.addAll(List.generate(10, (index) => ultimoValor + (index + 1) * 10));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gastos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        controller: _scrollController, // Asignar el controlador
        itemCount: gastos.length + 1, // +1 para el indicador de carga
        itemBuilder: (context, index) {
          if (index < gastos.length) {
            // Mostrar un elemento de la lista
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: Icon(Icons.money_off, color: Colors.green.shade800),
                title: Text(
                  'Gasto ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                trailing: Text(
                  '\$${gastos[index]}.00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            );
          } else {
            // Mostrar un indicador de carga al final de la lista
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}