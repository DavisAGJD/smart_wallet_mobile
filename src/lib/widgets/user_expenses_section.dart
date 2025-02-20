import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/chart_data.dart';
import '../models/category_data.dart';
import '../widgets/category_item.dart';

class UserExpensesSection extends StatelessWidget {
  final bool isLoading;
  final List<ChartData> chartData;
  final List<CategoryData> categoriesData;
  final double totalExpenses;
  final VoidCallback onViewExpensesPressed;

  const UserExpensesSection({
    Key? key,
    required this.isLoading,
    required this.chartData,
    required this.categoriesData,
    required this.totalExpenses,
    required this.onViewExpensesPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF228B22)))
          : chartData.isEmpty
              ? Center(child: Text('No hay datos disponibles'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: ElevatedButton(
                          onPressed: onViewExpensesPressed,
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
                      _buildChartSection(),
                      _buildChartLegend(),
                      _buildCategoryList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      child: SfCircularChart(
        margin: EdgeInsets.zero,
        series: <CircularSeries>[
          PieSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.name,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              // Se cambia a 'inside' para evitar el error de 'labelRect'
              labelPosition: ChartDataLabelPosition.inside,
              textStyle: TextStyle(fontSize: 12),
              builder: (dynamic data, dynamic point, dynamic series,
                  int pointIndex, int seriesIndex) {
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
    );
  }

  Widget _buildChartLegend() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: chartData.length,
        itemBuilder: (context, index) {
          final data = chartData[index];
          final percentage = totalExpenses > 0
              ? (data.value / totalExpenses * 100).toStringAsFixed(1)
              : '0.0';

          return Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(data.icon, color: data.color, size: 20),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: categoriesData.length,
      itemBuilder: (context, index) {
        return CategoryItem(
          categoryData: categoriesData[index],
          totalExpenses: totalExpenses,
        );
      },
    );
  }
}
