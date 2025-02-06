import 'package:flutter/material.dart';

class CategoryData {
  final String name;
  final double spent;
  final int transactions;
  final Color color;

  CategoryData({
    required this.name,
    required this.spent,
    required this.transactions,
    required this.color,
  });

  CategoryData copyWith({
    double? spent,
    int? transactions,
  }) {
    return CategoryData(
      name: name,
      spent: spent ?? this.spent,
      transactions: transactions ?? this.transactions,
      color: color,
    );
  }
}
