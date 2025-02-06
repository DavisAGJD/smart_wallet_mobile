import 'package:flutter/material.dart';
import 'third_screen.dart';
import '../widgets/step_indicator.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StepIndicator(color: Colors.green.shade200),
                      SizedBox(width: 5),
                      StepIndicator(color: Colors.green),
                      SizedBox(width: 5),
                      StepIndicator(color: Colors.green.shade200),
                    ],
                  ),
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/paper_plane.png',
                    height: 200,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 180,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    '¡Empieza a construir tu futuro financiero, ahora!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Registra tus gastos fácilmente y descubre a dónde va tu dinero',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 50,
              right: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThirdScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Empieza Ahora',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
