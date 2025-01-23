import 'package:flutter/material.dart';

class ExpenseItem extends StatelessWidget {
  final String name;
  final String amount;

  ExpenseItem({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.money_off, color: Colors.green.shade800),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }
}
