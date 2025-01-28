import 'package:flutter/material.dart';
import '../services/api_service_gastos.dart';
import '../services/api_service_info.dart';
import '../widgets/header_section.dart';
import '../widgets/expense_summary.dart';
import '../widgets/transaction_item.dart';
import '../widgets/quick_access_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/modal_gastos.dart';

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

      final response =
          await ApiServiceGastos().getGastosPaginados(userId, 1, 3);
      setState(() {
        _ultimosGastos = response['data'];
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

  void _mostrarModalGastos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GastosModal(
          onSave: (category, amount) async {
            final userId = await getUserId();
            if (userId != null) {
              try {
                _cargarUltimosGastos();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Gasto de $amount en $category agregado (simulado)')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al guardar el gasto: $e')),
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
                      'Accesos rápidos',
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
                          onTap: () {},
                        ),
                        QuickAccessCard(
                          icon: Icons.notifications,
                          title: 'Alertas',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Últimos Gastos',
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
                                    date: 'feb 21',
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
