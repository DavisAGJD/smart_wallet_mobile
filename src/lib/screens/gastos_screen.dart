import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service_gastos.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({Key? key}) : super(key: key);

  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  List<Map<String, dynamic>> _gastos = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;
  final ApiServiceGastos _apiServiceGastos = ApiServiceGastos();

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  /// Obtiene el userId almacenado en SharedPreferences.
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// Carga una página específica de gastos utilizando el endpoint paginado.
  Future<void> _loadPage(int page) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userId = await getUserId();
      if (userId == null) throw Exception('Usuario no autenticado');
      final response = await _apiServiceGastos.getGastosPaginadosByUserId(
          userId, page, _pageSize);
      List<Map<String, dynamic>> newGastos =
          List<Map<String, dynamic>>.from(response['data']);
      setState(() {
        _gastos = newGastos;
        _currentPage = page;
        if (response.containsKey('pagination') &&
            response['pagination']['totalPages'] != null) {
          _totalPages = response['pagination']['totalPages'];
        } else {
          _totalPages = 1;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Permite refrescar la lista mediante pull-to-refresh.
  Future<void> _refreshGastos() async {
    await _loadPage(1);
  }

  /// Obtiene el token almacenado en SharedPreferences.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Llama al servicio para eliminar un gasto y refresca la lista.
  void _deleteGasto(String gastoId) async {
    String? token = await getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario no autenticado")));
      return;
    }
    DeleteServiceGastos deleteService = DeleteServiceGastos(token: token);
    try {
      await deleteService.deleteGasto(gastoId);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gasto eliminado exitosamente")));
      _refreshGastos();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error eliminando gasto: $e")));
    }
  }

  /// Abre un diálogo para actualizar el gasto y llama al servicio correspondiente.
  void _updateGasto(Map<String, dynamic> gasto) async {
    final mainContext = context;
    final TextEditingController descriptionController =
        TextEditingController(text: gasto['descripcion']);
    final TextEditingController amountController =
        TextEditingController(text: gasto['monto'].toString());

    showDialog(
      context: mainContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Actualizar Gasto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Monto"),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                double? newAmount = double.tryParse(amountController.text);
                if (newAmount == null) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                      const SnackBar(content: Text("Monto inválido")));
                  return;
                }
                String newDescription = descriptionController.text;
                int categoryId = gasto['categoria_gasto_id'] is int
                    ? gasto['categoria_gasto_id']
                    : int.tryParse(gasto['categoria_gasto_id'].toString()) ?? 0;
                String gastoId = gasto['id_gasto'].toString();
                String? token = await getToken();
                if (token == null) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                      const SnackBar(content: Text("Usuario no autenticado")));
                  return;
                }
                PutServiceGastos putService = PutServiceGastos(token: token);
                try {
                  await putService.updateGasto(
                      gastoId, categoryId, newAmount, newDescription);
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                      const SnackBar(content: Text("Gasto actualizado")));
                  _loadPage(_currentPage);
                } catch (e) {
                  ScaffoldMessenger.of(mainContext).showSnackBar(
                      SnackBar(content: Text("Error actualizando gasto: $e")));
                }
              },
              child: const Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gastos',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshGastos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _gastos.length,
                      itemBuilder: (context, index) {
                        final gasto = _gastos[index];
                        DateTime fecha =
                            DateTime.tryParse(gasto['fecha'] ?? '') ??
                                DateTime(1970);
                        final formattedDate =
                            DateFormat('dd/MM/yyyy').format(fecha);
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Icon(Icons.money_off,
                                color: Colors.green.shade800),
                            title: Text(
                              gasto['descripcion'] ?? 'Gasto ${index + 1}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${gasto['monto'] ?? 0}.00',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _updateGasto(gasto),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteGasto(
                                      gasto['id_gasto'].toString()),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _currentPage > 1
                                  ? () => _loadPage(_currentPage - 1)
                                  : null,
                              child: const Text('Anterior'),
                            ),
                            const SizedBox(width: 20),
                            Text('Página $_currentPage de $_totalPages'),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: _currentPage < _totalPages
                                  ? () => _loadPage(_currentPage + 1)
                                  : null,
                              child: const Text('Siguiente'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
