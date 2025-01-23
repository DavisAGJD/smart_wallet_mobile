import 'package:flutter/material.dart';
import '../services/api_service_gastos.dart';
import 'gastos_screen.dart';
import '../widgets/quick_access_card.dart';
import '../widgets/expense_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _ultimosGastos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarUltimosGastos();
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
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
          await ApiServiceGastos().getGastosPaginados(userId, 1, 5);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SmartWallet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Lógica para notificaciones
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(),
            SizedBox(height: 20),
            _buildQuickAccessSection(context),
            SizedBox(height: 20),
            _buildRecentExpensesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lógica para agregar un nuevo gasto
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola Geovany!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Aquí tienes un resumen de tus finanzas:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo Actual',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'S-250',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        QuickAccessCard(
          title: 'Restos',
          icon: Icons.fastfood,
          color: Colors.orange,
          onTap: () {},
        ),
        QuickAccessCard(
          title: 'Gastos',
          icon: Icons.attach_money,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GastosScreen()),
            );
          },
        ),
        QuickAccessCard(
          title: 'Metas',
          icon: Icons.flag,
          color: Colors.purple,
          onTap: () {},
        ),
        QuickAccessCard(
          title: 'Recordatorios',
          icon: Icons.notifications,
          color: Colors.red,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildRecentExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Últimos Gastos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: _isLoading
                  ? [CircularProgressIndicator()]
                  : _ultimosGastos.isEmpty
                      ? [Text('No hay gastos recientes')]
                      : _ultimosGastos.map((gasto) {
                          return Column(
                            children: [
                              ExpenseItem(
                                name: gasto['descripcion'] ?? 'Sin descripción',
                                amount: '\$${gasto['monto'] ?? '0.00'}',
                              ),
                              Divider(),
                            ],
                          );
                        }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
