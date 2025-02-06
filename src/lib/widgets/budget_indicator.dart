import 'package:flutter/material.dart';

class BudgetIndicator extends StatelessWidget {
  final double monthlyBudget;
  final double totalExpenses;
  final int daysLeftInMonth;
  final double dailyBudget;
  final Function(int) onSectionChanged;
  final int currentSection;

  const BudgetIndicator({
    required this.monthlyBudget,
    required this.totalExpenses,
    required this.daysLeftInMonth,
    required this.dailyBudget,
    required this.onSectionChanged,
    required this.currentSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.shopping_cart,
                      color: currentSection == 0
                          ? Colors.greenAccent
                          : Colors.white),
                  label: Text('Gastos',
                      style: TextStyle(
                          color: currentSection == 0
                              ? Colors.greenAccent
                              : Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                        color: currentSection == 0
                            ? Colors.greenAccent
                            : Colors.white54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: currentSection == 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  onPressed: () => onSectionChanged(0),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.flag,
                      color: currentSection == 1
                          ? Colors.greenAccent
                          : Colors.white),
                  label: Text('Metas',
                      style: TextStyle(
                          color: currentSection == 0
                              ? Colors.greenAccent
                              : Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(
                        color: currentSection == 0
                            ? Colors.greenAccent
                            : Colors.white54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    backgroundColor: currentSection == 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  onPressed: () => onSectionChanged(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
