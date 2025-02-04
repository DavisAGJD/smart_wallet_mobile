// home_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service_gastos.dart';
import '../services/api_service_info.dart';
import '../widgets/header_section.dart';
import '../widgets/expense_summary.dart';
import '../widgets/transaction_item.dart';
import '../widgets/quick_access_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/modal_gastos.dart';
import '../widgets/modal_alertas.dart';
import '../widgets/modal_add_goal.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _ultimosGastos = [];
  bool _isLoading = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _cargarUltimosGastos();
    _cargarNombreUsuario();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final userInfo = await ApiServiceInfo().getUserInfo();
      setState(() {
        _userName = userInfo['nombre_usuario'] ?? 'Usuario';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el nombre del usuario: $e')),
      );
    }
  }

  Future<void> _cargarUltimosGastos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await getUserId();
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener todos los gastos del usuario
      final List<Map<String, dynamic>> response =
          await ApiServiceGastos().getGastosByUserId(userId);

      // Ordenar los gastos por fecha (asumiendo que hay un campo 'fecha' en cada gasto)
      final gastosOrdenados = response
          .where((gasto) => gasto['fecha'] != null)
          .toList()
        ..sort((a, b) => b['fecha'].compareTo(a['fecha']));

      // Tomar los últimos 3 gastos
      final ultimosGastos = gastosOrdenados.take(3).toList();

      setState(() {
        _ultimosGastos = ultimosGastos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar últimos gastos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarModalGastos(BuildContext context) async {
    final token = await getToken(); // Obtén el token
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener el token de autenticación')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GastosModal(
          onSave: (String category, double amount, String description) async {
            final userId = await getUserId();
            if (userId != null) {
              try {
                _cargarUltimosGastos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al guardar el gasto: $e')),
                );
              }
            }
          },
          token: token, // Pasa el token al modal
        );
      },
    );
  }

  void _mostrarModalMetas(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MetasAddAmountModal();
      },
    );
  }

  void _mostrarModalRecordatorios(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RecordatoriosModal(
          onSave: (description, date) async {
            final userId = await getUserId();
            if (userId != null) {
              try {
                // Aquí puedes agregar la lógica para guardar el recordatorio en tu API
                // Por ejemplo:
                // await ApiServiceRecordatorios().agregarRecordatorio(userId, description, date);

                // Muestra un mensaje de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Recordatorio "$description" agregado (simulado)'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error al guardar el recordatorio: $e')),
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF228B22),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderSection(userName: _userName),
              const ExpenseSummary(),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accesos rapidos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33404F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        QuickAccessCard(
                          icon: Icons.attach_money,
                          title: 'Gastos',
                          onTap: () {
                            _mostrarModalGastos(context);
                          },
                        ),
                        QuickAccessCard(
                          icon: Icons.flag,
                          title: 'Metas',
                          onTap: () {
                            _mostrarModalMetas(context);
                          },
                        ),
                        QuickAccessCard(
                          icon: Icons.notifications,
                          title: 'Alertas',
                          onTap: () {
                            _mostrarModalRecordatorios(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Ultimos Gastos',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33404F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : _ultimosGastos.isEmpty
                            ? Text('No hay gastos recientes')
                            : Column(
                                children: _ultimosGastos.map((gasto) {
                                  return TransactionItem(
                                    title: gasto['descripcion'] ??
                                        'Sin descripción',
                                    type: 'Gasto',
                                    amount: double.tryParse(
                                            gasto['monto'].toString()) ??
                                        0.00,
                                    date: DateFormat('dd/MM/yyyy')
                                        .format(DateTime.parse(gasto['fecha'])),
                                  );
                                }).toList(),
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarModalGastos(context);
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
