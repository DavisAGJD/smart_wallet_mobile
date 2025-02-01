import 'package:flutter/material.dart';

class BudgetIndicator extends StatelessWidget {
  final double monthlyBudget;
  final double totalExpenses;
  final int daysLeftInMonth;
  final double dailyBudget;

  const BudgetIndicator({
    required this.monthlyBudget,
    required this.totalExpenses,
    required this.daysLeftInMonth,
    required this.dailyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = monthlyBudget - totalExpenses;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Presupuesto restante:',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text('\$${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: totalExpenses / monthlyBudget,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          SizedBox(height: 12),
          Text(
            'Gasto diario disponible: \$${dailyBudget.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
