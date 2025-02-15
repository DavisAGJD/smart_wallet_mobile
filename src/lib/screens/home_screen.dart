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
import '../widgets/custom_fab.dart';
import 'scanner_screen.dart';
import 'voice_screen.dart';

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

      final List<Map<String, dynamic>> response =
          await ApiServiceGastos().getGastosByUserId(userId);

      final gastosOrdenados = response
          .where((gasto) => gasto['fecha'] != null)
          .toList()
        ..sort((a, b) => b['fecha'].compareTo(a['fecha']));

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
    final token = await getToken();
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
          token: token,
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
        return RecordatoriosModal();
      },
    );
  }

  void _navegarAScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    ).then((value) {
      if (value == true) {
        _cargarUltimosGastos();
      }
    });
  }

  void _navegarAVoz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VoiceScreen()),
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
      floatingActionButton: CustomFAB(
        onScanPressed: () => _navegarAScanner(context),
        onVoicePressed: () => _navegarAVoz(context),
      ),
    );
  }
}
