import 'package:flutter/material.dart';
import 'second_screen.dart';
import '../widgets/step_indicator.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtén las dimensiones de la pantalla
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

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
          // Usamos un Padding proporcional al ancho de la pantalla
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            // Si el contenido puede exceder en pantallas muy pequeñas, es buena idea envolverlo en un SingleChildScrollView
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sección superior: indicadores y logo
                      Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StepIndicator(color: Colors.green),
                              SizedBox(width: screenWidth * 0.02),
                              StepIndicator(color: Colors.green.shade200),
                              SizedBox(width: screenWidth * 0.02),
                              StepIndicator(color: Colors.green.shade200),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          Image.asset(
                            'assets/coins.png',
                            height: screenHeight * 0.3,
                          ),
                        ],
                      ),
                      // Sección intermedia: textos
                      Column(
                        children: [
                          Text(
                            '¡Dale un giro a tus finanzas personales!',
                            style: TextStyle(
                              // Tamaño de fuente relativo al ancho de la pantalla
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Empieza hoy tu camino hacia la estabilidad financiera',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // Sección inferior: botón de navegación
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SecondScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                              horizontal: screenWidth * 0.1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            'Siguiente',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
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
          ),
        ),
      ),
    );
  }
}
