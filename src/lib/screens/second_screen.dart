import 'package:flutter/material.dart';
import 'third_screen.dart';
import '../widgets/step_indicator.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Fondo degradado sutil
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Parte superior: indicadores y gráfico
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StepIndicator(color: Colors.green.shade200),
                        const SizedBox(width: 8),
                        StepIndicator(color: Colors.green),
                        const SizedBox(width: 8),
                        StepIndicator(color: Colors.green.shade200),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/paper_plane.png',
                      height: screenHeight * 0.3,
                    ),
                  ],
                ),
                // Parte intermedia: textos informativos
                Column(
                  children: [
                    Text(
                      '¡Empieza a construir tu futuro financiero, ahora!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Registra tus gastos fácilmente y descubre a dónde va tu dinero',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                // Parte inferior: botón para continuar
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ThirdScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
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
        ),
      ),
    );
  }
}
