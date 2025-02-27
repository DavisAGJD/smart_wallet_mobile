import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/api_service_profile.dart';

class ExpenseSummary extends StatefulWidget {
  const ExpenseSummary({Key? key}) : super(key: key);

  @override
  // Renombramos la clase de estado para que sea pública:
  ExpenseSummaryState createState() => ExpenseSummaryState();
}

class ExpenseSummaryState extends State<ExpenseSummary> {
  double? ingresos;
  double? totalGastos;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchFinances();
  }

  // Este método se hace público para poder invocarlo desde HomeScreen.
  Future<void> fetchFinances() async {
    try {
      final apiService = FinancesApiService();
      final data = await apiService.getGastosYSalario();

      final dynamic ingresosData = data['ingresos'];
      final dynamic totalGastosData = data['totalGastos'];

      final double ingresosParsed = ingresosData is num
          ? ingresosData.toDouble()
          : double.tryParse(ingresosData.toString()) ?? 0.0;
      final double totalGastosParsed = totalGastosData is num
          ? totalGastosData.toDouble()
          : double.tryParse(totalGastosData.toString()) ?? 0.0;

      setState(() {
        ingresos = ingresosParsed;
        totalGastos = totalGastosParsed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final double presupuesto = ingresos ?? 0;
    final double gastado = totalGastos ?? 0;
    final double porcentaje = (presupuesto > 0) ? (gastado / presupuesto) : 0.0;
    final String porcentajeFormateado = (porcentaje * 100).toStringAsFixed(0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Gastos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_downward,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '\$${gastado.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearPercentIndicator(
              width: MediaQuery.of(context).size.width * 0.9,
              lineHeight: 12,
              percent: porcentaje.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.redAccent,
              barRadius: const Radius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '$porcentajeFormateado% de tu presupuesto',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Presupuesto: \$${presupuesto.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'Gastado: \$${gastado.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
