import 'package:flutter/material.dart';
import 'second_screen.dart';
import '../widgets/step_indicator.dart';

class FirstScreen extends StatelessWidget {
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
                      StepIndicator(color: Colors.green),
                      SizedBox(width: 5),
                      StepIndicator(color: Colors.green.shade200),
                      SizedBox(width: 5),
                      StepIndicator(color: Colors.green.shade200),
                    ],
                  ),
                  SizedBox(height: 50),
                  Image.asset(
                    'assets/coins.png',
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
                    '¡Dale un giro a tus finanzas personales!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Empieza hoy tu camino hacia la estabilidad financiera',
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
                    MaterialPageRoute(builder: (context) => SecondScreen()),
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
                  'Siguiente',
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
