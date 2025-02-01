import 'package:flutter/material.dart';
import '../models/category_data.dart';
import '../utils/graphics_constants.dart';

class CategoryItem extends StatelessWidget {
  final CategoryData categoryData;
  final double totalExpenses;

  const CategoryItem({
    required this.categoryData,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalExpenses > 0
        ? (categoryData.spent / totalExpenses).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getCategoryIcon(categoryData.name),
                  color: categoryData.color, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(categoryData.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800])),
                    SizedBox(height: 4),
                    Text(
                      '$percentage% del total gastado',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text('${categoryData.transactions} trans.',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(categoryData.color),
              minHeight: 10,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
