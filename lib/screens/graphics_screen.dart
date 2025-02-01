import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/api_service_gastos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gastos_screen.dart';
import '../widgets/budget_indicator.dart';
import '../widgets/category_item.dart';
import '../models/chart_data.dart';
import '../models/category_data.dart';
import '../utils/graphics_constants.dart';

class GraphicsScreen extends StatefulWidget {
  @override
  _GraphicsScreenState createState() => _GraphicsScreenState();
}

class _GraphicsScreenState extends State<GraphicsScreen> {
  final ApiServiceGastosGrafica _apiService = ApiServiceGastosGrafica();
  List<ChartData> chartData = [];
  List<CategoryData> categoriesData = [];
  double totalExpenses = 0.0;
  bool isLoading = true;
  double monthlyBudget = 500.0;
  int daysLeftInMonth = 0;
  double dailyBudget = 0.0;
  double maxCategorySpent = 0.0;
  late FocusNode _focusNode;
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _calculateDaysLeft();
    _initializeFocusNode();
    // Carga inicial después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      await fetchExpenses();
    } catch (e) {
      print('Error en carga inicial: $e');
      setState(() => isLoading = false);
    }
  }

  void _initializeFocusNode() {
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && mounted && !_firstLoad) {
        _refreshData();
      }
      _firstLoad = false;
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      chartData.clear();
      categoriesData.clear();
      totalExpenses = 0.0;
    });

    try {
      await fetchExpenses();
    } catch (e) {
      print('Error al actualizar datos: $e');
      setState(() => isLoading = false);
    }
  }

  void _calculateDaysLeft() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);
    daysLeftInMonth = lastDay.difference(now).inDays + 1;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> fetchExpenses() async {
    try {
      final token = await getToken();
      final userId = await getUserId();

      if (token == null || userId == null) {
        throw Exception('No se pudo obtener el token o el ID del usuario');
      }

      final expenses = await _apiService.obtenerGastosPorUsuario(userId, token);

      if (expenses == null || expenses.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final now = DateTime.now();
      final filteredExpenses = expenses.where((expense) {
        final fecha = DateTime.tryParse(expense['fecha'] ?? '');
        return fecha != null &&
            fecha.month == now.month &&
            fecha.year == now.year;
      }).toList();

      totalExpenses = filteredExpenses.fold(0.0, (sum, expense) {
        return sum + (double.tryParse(expense['monto'].toString()) ?? 0.0);
      });

      final grouped = <String, CategoryData>{};
      for (var expense in filteredExpenses) {
        final categoriaId = expense['categoria_gasto_id'].toString();
        final monto = double.tryParse(expense['monto'].toString()) ?? 0.0;
        final nombre = expense['nombre_categoria'] ?? 'Otros';

        if (!grouped.containsKey(categoriaId)) {
          grouped[categoriaId] = CategoryData(
            name: nombre,
            spent: 0.0,
            transactions: 0,
            color: chartColors[grouped.length % chartColors.length],
          );
        }

        grouped[categoriaId] = grouped[categoriaId]!.copyWith(
          spent: grouped[categoriaId]!.spent + monto,
          transactions: grouped[categoriaId]!.transactions + 1,
        );
      }

      categoriesData =
          grouped.values.where((category) => category.name != "Otros").toList();
      maxCategorySpent = categoriesData.fold(
          0.0, (max, item) => item.spent > max ? item.spent : max);
      dailyBudget = (monthlyBudget - totalExpenses) / daysLeftInMonth;

      chartData = categoriesData
          .map((category) => ChartData(
                category.name,
                getCategoryIcon(category.name),
                category.spent,
                category.color,
              ))
          .toList();

      if (mounted) setState(() => isLoading = false);
    } catch (error) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onFocusChange: (hasFocus) {
        if (hasFocus && mounted) {
          _refreshData();
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFF228B22),
        appBar: AppBar(
          backgroundColor: Color(0xFF228B22),
          title: Text('Resumen de Gastos',
              style: TextStyle(fontSize: 24, color: Colors.white)),
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Gastos Mensuales',
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  BudgetIndicator(
                    monthlyBudget: monthlyBudget,
                    totalExpenses: totalExpenses,
                    daysLeftInMonth: daysLeftInMonth,
                    dailyBudget: dailyBudget,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF228B22)))
                    : chartData.isEmpty
                        ? Center(child: Text('No hay datos disponibles'))
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: 20, left: 20, right: 20),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                GastosScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF228B22),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      minimumSize: Size(double.infinity, 50),
                                      elevation: 3,
                                    ),
                                    child: Text(
                                      'Ver Gastos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Container(
                                  height: 300,
                                  padding: EdgeInsets.all(20),
                                  child: SfCircularChart(
                                    margin: EdgeInsets.zero,
                                    series: <CircularSeries>[
                                      PieSeries<ChartData, String>(
                                        dataSource: chartData,
                                        xValueMapper: (ChartData data, _) =>
                                            data.name,
                                        yValueMapper: (ChartData data, _) =>
                                            data.value,
                                        pointColorMapper: (ChartData data, _) =>
                                            data.color,
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true,
                                          labelPosition:
                                              ChartDataLabelPosition.outside,
                                          textStyle: TextStyle(fontSize: 12),
                                          builder:
                                              (dynamic data, _, __, ___, ____) {
                                            return Icon(
                                              (data as ChartData).icon,
                                              color: data.color,
                                              size: 24,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 80,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: chartData.length,
                                    itemBuilder: (context, index) {
                                      final data = chartData[index];
                                      final percentage = totalExpenses > 0
                                          ? (data.value / totalExpenses * 100)
                                              .toStringAsFixed(1)
                                          : '0.0';

                                      return Container(
                                        margin: EdgeInsets.only(right: 10),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: data.color.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  data.color.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(data.icon,
                                                color: data.color, size: 20),
                                            SizedBox(width: 8),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(data.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.grey[800],
                                                    )),
                                                Text('$percentage%',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: categoriesData.length,
                                  itemBuilder: (context, index) {
                                    return CategoryItem(
                                        categoryData: categoriesData[index],
                                        totalExpenses: totalExpenses);
                                  },
                                ),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
