import 'package:flutter/material.dart';

const List<Color> chartColors = [
  Colors.redAccent,
  Colors.orangeAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.blueAccent,
];

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Alimentación':
      return Icons.restaurant;
    case 'Transporte':
      return Icons.directions_bus;
    case 'Entretenimiento':
      return Icons.movie;
    case 'Educación':
      return Icons.school;
    case 'Salud':
      return Icons.favorite;
    case 'Hogar':
      return Icons.home;
    case 'Ropa':
      return Icons.checkroom;
    case 'Tecnología':
      return Icons.computer;
    case 'Viajes':
      return Icons.flight;
    default:
      return Icons.category;
  }
}
