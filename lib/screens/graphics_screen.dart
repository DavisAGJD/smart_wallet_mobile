import 'package:flutter/material.dart';

class GraphicsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráficos'),
      ),
      body: Center(
        child: Text(
          'Pantalla de Gráficos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
