import 'package:flutter/material.dart';

class TransactionItem extends StatelessWidget {
  final String title;
  final String type;
  final double amount;
  final String date;

  const TransactionItem({
    Key? key,
    required this.title,
    required this.type,
    required this.amount,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            // Usar Expanded para limitar el ancho del texto
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF33404F),
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Evitar desbordamiento de texto
                ),
                const SizedBox(height: 5),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF33404F),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  color: amount >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF33404F),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
