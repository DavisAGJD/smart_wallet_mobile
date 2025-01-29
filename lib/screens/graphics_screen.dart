import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service_gastos.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphicsScreen extends StatefulWidget {
  @override
  _GraphicsScreenState createState() => _GraphicsScreenState();
}

class _GraphicsScreenState extends State<GraphicsScreen> {
  final ApiServiceGastosGrafica _apiService = ApiServiceGastosGrafica();
  List<ChartData> chartData = [];
  double totalExpenses = 0.0;
  bool isLoading = true;

  final List<Color> _chartColors = [
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.blue,
    Colors.pink,
    Colors.teal,
    Colors.yellow
  ];

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId'); // Asegúrate de que el key sea correcto
  }

  Future<void> fetchExpenses() async {
    try {
      final token = await getToken();
      final userId = await getUserId();

      if (token == null || userId == null) {
        throw Exception('No se pudo obtener el token o el ID del usuario');
      }

      print('Obteniendo gastos para el usuario: $userId');
      final expenses = await _apiService.obtenerGastosPorUsuario(userId, token);
      print('Todos los gastos obtenidos: $expenses');

      if (expenses.isEmpty) {
        setState(() {
          isLoading = false;
          chartData = [];
        });
        return;
      }

      // Obtener el mes y año actuales
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Filtrar los gastos solo del mes actual
      final filteredExpenses = expenses.where((expense) {
        final fecha = DateTime.tryParse(expense['fecha'] ?? '');
        return fecha != null &&
            fecha.month == currentMonth &&
            fecha.year == currentYear;
      }).toList();

      print('Gastos filtrados para el mes actual: $filteredExpenses');

      if (filteredExpenses.isEmpty) {
        setState(() {
          isLoading = false;
          chartData = [];
        });
        return;
      }

      final total = filteredExpenses.fold(0.0, (acc, expense) {
        final monto = double.tryParse(expense['monto'].toString()) ?? 0.0;
        return acc + monto;
      });

      final groupedExpenses = <String, Map<String, dynamic>>{};

      for (var expense in filteredExpenses) {
        final categoriaId = expense['categoria_gasto_id'].toString();
        final monto = double.tryParse(expense['monto'].toString()) ?? 0.0;

        if (!groupedExpenses.containsKey(categoriaId)) {
          groupedExpenses[categoriaId] = {
            'nombre': expense['nombre_categoria'] ?? 'Desconocido',
            'monto': 0.0,
          };
        }
        groupedExpenses[categoriaId]!['monto'] += monto;
      }

      final categoriesData = groupedExpenses.values.toList()
        ..sort((a, b) => b['monto'].compareTo(a['monto']));

      final pieData = List.generate(categoriesData.length, (index) {
        return ChartData(
          categoriesData[index]['nombre'],
          categoriesData[index]['monto'],
          _chartColors[index % _chartColors.length],
        );
      }).take(4).toList();

      setState(() {
        totalExpenses = total;
        chartData = pieData;
        isLoading = false;
      });

      print('Gastos procesados para la gráfica: $chartData');
    } catch (error) {
      print('Error al obtener gastos del usuario: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF228B22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        elevation: 0,
        title: const Text(
          'Gráficos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            color: const Color(0xFF228B22),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Gastos del Mes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '\$${totalExpenses.toStringAsFixed(2)} gastados',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: isLoading
                    ? CircularProgressIndicator()
                    : (chartData.isEmpty
                        ? const Text(
                            'No hay datos disponibles para este mes',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : SfCircularChart(
                            title: ChartTitle(
                              text: 'Distribución de Gastos',
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            legend: Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            series: <CircularSeries>[
                              PieSeries<ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (ChartData data, _) =>
                                    data.category,
                                yValueMapper: (ChartData data, _) => data.value,
                                pointColorMapper: (ChartData data, _) =>
                                    data.color,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                animationDuration: 1500,
                              ),
                            ],
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}
