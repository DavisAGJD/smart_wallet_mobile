import 'package:flutter/material.dart';
import '../services/api_service_gastos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gastos_screen.dart';
import '../widgets/budget_indicator.dart';
import '../models/chart_data.dart';
import '../models/category_data.dart';
import '../utils/graphics_constants.dart';
import '../widgets/user_expenses_section.dart';
import '../widgets/goals_section.dart';
import '../widgets/reminders_section.dart';

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
  int _currentSection = 0;

  @override
  void initState() {
    super.initState();
    _calculateDaysLeft();
    _initializeFocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _handleSectionChange(int section) {
    setState(() => _currentSection = section);
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

      if (expenses.isEmpty) {
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
        if (hasFocus && mounted) _refreshData();
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
                  Text('Resumen usuario',
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
                    onSectionChanged: _handleSectionChange,
                    currentSection: _currentSection,
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _currentSection == 0
                    ? UserExpensesSection(
                        key: ValueKey('expenses_section'),
                        isLoading: isLoading,
                        chartData: chartData,
                        categoriesData: categoriesData,
                        totalExpenses: totalExpenses,
                        onViewExpensesPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GastosScreen(),
                          ),
                        ),
                      )
                    : _currentSection == 1
                        ? GoalsSection(
                            key: ValueKey('goals_section'),
                            isLoading: isLoading,
                            onSave: (String nombre,
                                String descripcion,
                                double monto,
                                DateTime fecha,
                                String categoriaId,
                                String categoriaNombre) {
                              // Lógica de guardado...
                            },
                          )
                        : ReminderSection(
                            // Sección corregida
                            key: ValueKey('reminders_section'),
                            onDateSelected: (date) {
                              // Lógica para selección de fecha
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
