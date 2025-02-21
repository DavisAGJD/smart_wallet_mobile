import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String userName;

  const HeaderSection({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Fila superior con menú y logo centrado
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícono del menú alineado a la izquierda
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              // Logo y título centrados
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'SmartWallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Espacio para balancear el diseño
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          // Textos de bienvenida
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Hola $userName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Aqui tus gastos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
